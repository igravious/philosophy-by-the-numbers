#!/usr/bin/env ruby
# == Zotero Collection Snapshot (Phase 0)
#
# Creates a frozen, self-consistent JSON snapshot of the "emerging philosophy"
# Zotero collection (root +8QSGBCWF+, mirrored into six decade subcollections)
# for the source-material audit (docs/ep/emerging-philosophy-audit-plan.md §3).
#
# READ-ONLY: performs only GET requests against the Zotero Web API v3.
#
# == What it does
# 1. Reads the library version (Last-Modified-Version header) from the first
#    multi-object response (/collections/top listing).
# 2. Recursively walks the root collection and its subcollections, fetching
#    items with include=data,bib (+notes+ is not a valid include; note content
#    rides in data.note), deduplicated by item key.
# 3. Re-reads the library version from the same endpoint; on mismatch discards
#    everything and re-dumps (max 3 attempts, then aborts without writing).
# 4. Writes sources/emerging_philosophy/dumps/snapshot-<UTC-timestamp>.json as
#    a wrapper object (metadata + items) and prints its SHA256.
# 5. Verifies: (a) version stability, (b) object accounting, (c) reconciliation
#    against the named baseline artifact (count-level required, key-level
#    advisory), (d) membership invariant for top-level items (exactly
#    {root + one leaf}), (e) child-parent integrity (orphan register split
#    into standalone vs broken-ref).
#
# == Configuration (via environment, never hardcoded)
# * +ZOTERO_USER_ID+  - numeric user id (1248965)
# * +ZOTERO_API_KEY+  - API key; read access suffices, writes are never made
#
# == Usage
#   bin/bundle exec ruby scripts/zotero_snapshot.rb
#
require 'json'
require 'digest'
require 'time'
require 'fileutils'
require_relative '../lib/zotero/client'

module ZoteroSnapshot
	ROOT_KEY = '8QSGBCWF'
	DUMP_DIR = File.expand_path('../sources/emerging_philosophy/dumps', __dir__)
	BASELINE_FILE = File.join(DUMP_DIR, 'baseline-2026-10-15.json')
	BASELINE_COUNTS = { 'total' => 263, 'top_level' => 161, 'attachments' => 82, 'notes' => 20 }.freeze
	CHILD_TYPES = %w[attachment note].freeze
	MAX_ATTEMPTS = 3
	TITLE_MAX = 60
	LIST_MAX = 30
	INCLUDE = 'data,bib'

	module_function

	# Runs the snapshot protocol and prints the verification report.
	#
	# @return [void]
	def run
		Zotero.load_env_file
		user_id = ENV['ZOTERO_USER_ID'].to_s.strip
		api_key = ENV['ZOTERO_API_KEY'].to_s.strip
		abort 'FATAL: ZOTERO_USER_ID / ZOTERO_API_KEY not set (see .env.template)' if user_id.empty? || api_key.empty?

		conn = Zotero.connection(api_key)
		version_path = "/users/#{user_id}/collections/top?limit=#{Zotero::Per_Page}"

		# Version-consistency protocol: V1 -> full dump -> V2; mismatch re-dumps.
		v1 = v2 = nil
		root_name = nil
		acc = nil
		attempt = 0
		loop do
			attempt += 1
			v1, tops = library_version(conn, version_path)
			root = tops.find { |c| c['key'] == ROOT_KEY }
			abort "FATAL: root collection #{ROOT_KEY} not found among top-level collections" if root.nil?
			root_name = root['data']['name']

			acc = { 'by_key' => {}, 'appearances' => 0, 'walked' => [] }
			walk_collection(conn, user_id, ROOT_KEY, root_name, acc)

			v2, = library_version(conn, version_path)
			break if v1 == v2
			warn "attempt #{attempt}: library version changed during dump (#{v1} -> #{v2}); discarding and re-dumping"
			if attempt >= MAX_ATTEMPTS
				abort "FATAL: library version unstable after #{MAX_ATTEMPTS} attempts; no snapshot written"
			end
			sleep 2
		end

		retrieved_at = Time.now.utc
		items = acc['by_key'].values.sort_by { |i| i['key'] }
		top_level = items.reject { |i| CHILD_TYPES.include?(i['data']['itemType']) }
		children = items.select { |i| CHILD_TYPES.include?(i['data']['itemType']) }
		attachments = children.select { |i| i['data']['itemType'] == 'attachment' }
		notes = children.select { |i| i['data']['itemType'] == 'note' }

		counts = {
			'total' => items.size,
			'top_level' => top_level.size,
			'attachments' => attachments.size,
			'notes' => notes.size,
			'listings_seen' => acc['appearances'],
			'duplicates_dropped' => acc['appearances'] - items.size
		}

		verification = {
			'version_stability' => {
				'v1' => v1, 'v2' => v2, 'stable' => v1 == v2, 'attempts' => attempt
			},
			'object_accounting' => counts.merge(
				'balanced' => counts['total'] == counts['top_level'] + counts['attachments'] + counts['notes']
			),
			'baseline_reconciliation' => reconcile_baseline(acc['by_key'], counts),
			'membership_invariant' => membership_check(top_level),
			'child_parent_integrity' => child_parent_check(children, acc['by_key'])
		}

		metadata = {
			'retrieved_at' => retrieved_at.iso8601,
			'library' => { 'user_id' => user_id },
			'collection' => {
				'root_key' => ROOT_KEY,
				'root_name' => root_name,
				'collections_walked' => acc['walked']
			},
			'requests' => {
				'method' => 'GET (read-only)',
				'version_check' => version_path,
				'items' => "/users/#{user_id}/collections/{collection_key}/items?include=#{INCLUDE}&limit=#{Zotero::Per_Page}",
				'subcollections' => "/users/#{user_id}/collections/{collection_key}/collections?limit=#{Zotero::Per_Page}",
				'include' => INCLUDE,
				'limit' => Zotero::Per_Page
			},
			'last_modified_version' => v1,
			'counts' => counts,
			'verification' => verification
		}

		FileUtils.mkdir_p(DUMP_DIR)
		path = File.join(DUMP_DIR, "snapshot-#{retrieved_at.strftime('%Y%m%dT%H%M%SZ')}.json")
		File.write(path, JSON.pretty_generate({ 'metadata' => metadata, 'items' => items }))
		sha256 = Digest::SHA256.file(path).hexdigest

		print_report(verification, counts, path, sha256)
	end

	# Reads the library version from a multi-object endpoint.
	#
	# @param conn [Faraday::Connection]
	# @param path [String]
	# @return [Array(Integer, Array)] Last-Modified-Version and parsed body
	# @raise [RuntimeError] on HTTP error or missing header
	def library_version(conn, path)
		resp = conn.get(path)
		raise "Zotero API error #{resp.status}: #{resp.body}" unless resp.success?
		version = resp.headers['Last-Modified-Version']
		raise 'Last-Modified-Version header missing from multi-object response' if version.nil?
		[version.to_i, JSON.parse(resp.body)]
	end

	# Recursively fetches all items of a collection and its subcollections,
	# deduplicating by item key (items appear in multiple listings because the
	# root is mirrored into the decade subcollections).
	#
	# @param conn [Faraday::Connection]
	# @param user_id [String]
	# @param coll_key [String] collection key
	# @param coll_name [String] collection name
	# @param acc [Hash] accumulator: by_key, appearances, walked
	# @return [void]
	def walk_collection(conn, user_id, coll_key, coll_name, acc)
		acc['walked'] << { 'key' => coll_key, 'name' => coll_name }
		Zotero.paged_get(conn, "/users/#{user_id}/collections/#{coll_key}/items?include=#{INCLUDE}&limit=#{Zotero::Per_Page}") do |page|
			page.each do |item|
				acc['appearances'] += 1
				acc['by_key'][item['key']] ||= item
			end
		end
		Zotero.paged_get(conn, "/users/#{user_id}/collections/#{coll_key}/collections?limit=#{Zotero::Per_Page}") do |subs|
			subs.each { |sub| walk_collection(conn, user_id, sub['key'], sub['data']['name'], acc) }
		end
	end

	# Short display label for an item: title, else a plain-text note excerpt.
	#
	# @param item [Hash] Zotero item object
	# @return [String]
	def label(item)
		data = item['data'] || {}
		title = data['title'].to_s.strip
		return truncate(title, TITLE_MAX) unless title.empty?
		note = data['note'].to_s.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
		return "(note) #{truncate(note, TITLE_MAX)}" unless note.empty?
		"(untitled #{data['itemType']})"
	end

	# Truncates a string to max characters with an ellipsis.
	#
	# @param str [String]
	# @param max [Integer]
	# @return [String]
	def truncate(str, max)
		str.length > max ? "#{str[0, max - 1]}…" : str
	end

	# (c) Reconciliation against the named baseline artifact. Count-level is
	# required; key-level diff is advisory (the baseline lacks version headers).
	#
	# @param by_key [Hash] snapshot items keyed by item key
	# @param counts [Hash] snapshot object counts
	# @return [Hash] verification result for the metadata block
	def reconcile_baseline(by_key, counts)
		unless File.exist?(BASELINE_FILE)
			return { 'available' => false, 'reason' => "baseline artifact #{BASELINE_FILE} not found" }
		end
		baseline = JSON.parse(File.read(BASELINE_FILE))
		b_by_key = {}
		baseline.each { |i| b_by_key[i['key']] = i }
		b_children = baseline.select { |i| CHILD_TYPES.include?(i['data']['itemType']) }
		b_counts = {
			'total' => baseline.size,
			'top_level' => baseline.size - b_children.size,
			'attachments' => b_children.count { |i| i['data']['itemType'] == 'attachment' },
			'notes' => b_children.count { |i| i['data']['itemType'] == 'note' }
		}
		added = (by_key.keys - b_by_key.keys).sort.map { |k| { 'key' => k, 'title' => label(by_key[k]) } }
		removed = (b_by_key.keys - by_key.keys).sort.map { |k| { 'key' => k, 'title' => label(b_by_key[k]) } }
		{
			'available' => true,
			'baseline_file' => BASELINE_FILE,
			'expected_counts' => BASELINE_COUNTS,
			'baseline_counts' => b_counts,
			'snapshot_counts' => counts.slice('total', 'top_level', 'attachments', 'notes'),
			'count_diff' => BASELINE_COUNTS.keys.each_with_object({}) do |k, h|
				h[k] = counts[k] - b_counts[k]
			end,
			'key_level' => {
				'advisory' => true,
				'note' => 'advisory (baseline lacks version headers)',
				'added' => added,
				'removed' => removed
			}
		}
	end

	# (d) Membership invariant, top-level items only: each top-level item's
	# data.collections must be exactly {root key + one leaf key}.
	#
	# @param top_level [Array<Hash>] top-level snapshot items
	# @return [Hash] verification result with every exception listed
	def membership_check(top_level)
		exceptions = top_level.reject do |i|
			cols = i['data']['collections'] || []
			cols.size == 2 && cols.include?(ROOT_KEY)
		end.map do |i|
			{ 'key' => i['key'], 'title' => label(i), 'collections' => i['data']['collections'] || [] }
		end
		{
			'rule' => "top-level item in exactly 2 collections including #{ROOT_KEY} (root + one leaf)",
			'checked' => top_level.size,
			'exception_count' => exceptions.size,
			'exceptions' => exceptions
		}
	end

	# (e) Child-parent integrity: every attachment/note resolves its parentItem
	# to a key in the snapshot, or lands in the orphan register as +standalone+
	# (no parentItem set) or +broken-ref+ (parentItem key absent from snapshot).
	#
	# @param children [Array<Hash>] attachment and note items
	# @param by_key [Hash] snapshot items keyed by item key
	# @return [Hash] verification result with the orphan register
	def child_parent_check(children, by_key)
		standalone = []
		broken_ref = []
		resolved = 0
		children.each do |i|
			parent = i['data']['parentItem']
			if parent.nil? || parent == false || parent.to_s.strip.empty?
				standalone << { 'key' => i['key'], 'title' => label(i), 'itemType' => i['data']['itemType'] }
			elsif by_key.key?(parent)
				resolved += 1
			else
				broken_ref << { 'key' => i['key'], 'title' => label(i), 'itemType' => i['data']['itemType'], 'parentItem' => parent }
			end
		end
		{
			'children' => children.size,
			'resolved' => resolved,
			'orphans' => {
				'standalone_count' => standalone.size,
				'broken_ref_count' => broken_ref.size,
				'standalone' => standalone,
				'broken_ref' => broken_ref
			}
		}
	end

	# Prints the compact verification report to stdout.
	#
	# @param verification [Hash] the metadata verification block
	# @param counts [Hash] object counts
	# @param path [String] snapshot file path
	# @param sha256 [String] snapshot file SHA256
	# @return [void]
	def print_report(verification, counts, path, sha256)
		vs = verification['version_stability']
		puts '== Phase 0 snapshot report =='
		puts "(a) version-stability: V1=#{vs['v1']} V2=#{vs['v2']} stable=#{vs['stable']} (attempt #{vs['attempts']}/#{MAX_ATTEMPTS})"

		oa = verification['object_accounting']
		puts "(b) object accounting: total=#{oa['total']} = top-level=#{oa['top_level']} + attachments=#{oa['attachments']} + notes=#{oa['notes']} balanced=#{oa['balanced']}"
		puts "    listings_seen=#{counts['listings_seen']} duplicates_dropped=#{counts['duplicates_dropped']}"

		rec = verification['baseline_reconciliation']
		if rec['available']
			d = rec['count_diff']
			puts "(c) baseline reconciliation (vs #{File.basename(rec['baseline_file'])}):"
			puts "    count diff: total=#{fmt_diff(d['total'])} top-level=#{fmt_diff(d['top_level'])} attachments=#{fmt_diff(d['attachments'])} notes=#{fmt_diff(d['notes'])}"
			puts "    key-level #{rec['key_level']['note']}:"
			print_key_list('added', rec['key_level']['added'])
			print_key_list('removed', rec['key_level']['removed'])
		else
			puts "(c) baseline reconciliation: UNAVAILABLE - #{rec['reason']}"
		end

		mi = verification['membership_invariant']
		puts "(d) membership invariant (#{mi['rule']}): #{mi['exception_count']} exceptions / #{mi['checked']} checked"
		mi['exceptions'].each { |e| puts "    #{e['key']} #{e['title']} collections=#{e['collections'].inspect}" }

		cp = verification['child_parent_integrity']
		orph = cp['orphans']
		puts "(e) child-parent integrity: #{cp['children']} children, #{cp['resolved']} resolved, orphans standalone=#{orph['standalone_count']} broken-ref=#{orph['broken_ref_count']}"
		orph['standalone'].each { |o| puts "    standalone #{o['key']} (#{o['itemType']}) #{o['title']}" }
		orph['broken_ref'].each { |o| puts "    broken-ref #{o['key']} (#{o['itemType']}) #{o['title']} parent=#{o['parentItem']}" }

		puts "snapshot: #{path}"
		puts "sha256:   #{sha256}"
	end

	# Formats a count difference with an explicit sign.
	#
	# @param diff [Integer]
	# @return [String]
	def fmt_diff(diff)
		diff.negative? ? diff.to_s : "+#{diff}"
	end

	# Prints an added/removed key list, truncated to LIST_MAX entries.
	#
	# @param name [String] list label
	# @param list [Array<Hash>] entries with key and title
	# @return [void]
	def print_key_list(name, list)
		puts "      #{name}: #{list.size}"
		list.first(LIST_MAX).each { |e| puts "        #{e['key']} #{e['title']}" }
		puts "        … #{list.size - LIST_MAX} more (full list in snapshot metadata)" if list.size > LIST_MAX
	end
end

ZoteroSnapshot.run if __FILE__ == $PROGRAM_NAME
