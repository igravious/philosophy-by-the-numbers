#!/usr/bin/env ruby
# == Regeneration Verification (non-destructive)
#
# Verifies that the decisions-ledger mechanism preserves human rulings
# across sheet regeneration, under the TWO-CHANNEL ruling model
# (membership and containment are orthogonal; ledger last-wins is per
# (pair, channel)). Compares review-sheet-v1.yaml (human-edited),
# decisions.jsonl (migrated ledger) and review-sheet-v2.yaml (regenerated
# under the ledger) and checks:
#
# 1. Every ledger ruling appears on its edge in v2 (all mirror copies):
#    membership rulings on the rows' `gate:`, containment rulings on
#    `containment:`.
# 2. Every legacy project anchor exists as an anchored audit unit; every
#    migrated cluster's effective members are in ONE v2 cluster; every split item (assignment
#    NEW, or membership describes/unrelated to retained cluster-mates) is
#    NOT clustered with them.
# 3. The v2 cluster containing EKT6SMX2 (old EP-001) contains all four of
#    EKT6SMX2, PJ6LLK7F, 7LCVEML6, IVKJ4VAN.
# 4. Ruling maps, v1 vs v2, per channel: no v1 ruling lost or changed;
#    every v2 membership ruling is ledger-explained; every v2 containment
#    ruling is ledger-explained or a pre-typed contained-in-book default.
# 5. regen-idmap.json was written and is sane (EP-001 -> a cluster
#    containing the same 4 members; EP-004 retired).
# 6. Two-channel spot checks: EP-011's intro<->issue pair shows membership
#    same-project AND containment part-of on the same rows, and the cluster
#    holds; the two LFP7FHS2 sister-volume pairs (3VEBTE69, I7MAW4IQ) show
#    containment unrelated with BLANK membership.
# 7. Population keys match the snapshot; EP targets resolve; audit-unit and
#    artifact IDs are unique; singleton IDs, inventory structure/rulings, and
#    NEEDS-YOU flags agree with the registry and inventory contents.
# 8. Optional preservation check (ZOTERO_PRESERVATION_BASELINE): baseline
#    inventories and candidate links persist except for ledger-authorized changes.
#
# Prints PASS/FAIL per check with details on failure; exit 1 on any FAIL.
#
# == Usage
#   bin/bundle exec ruby scripts/zotero_verify_decisions.rb
#
require 'json'
require 'yaml'
require 'set'
require_relative 'zotero_singleton_ids'

load File.expand_path('zotero_migrate_decisions.rb', __dir__)

module ZoteroVerifyDecisions
	V1 = File.expand_path('../sources/emerging_philosophy/review-sheet-v1.yaml', __dir__)
	V2 = ENV['ZOTERO_SHEET_YAML'] || File.expand_path('../sources/emerging_philosophy/review-sheet-v2.yaml', __dir__)
	LEDGER = ENV['ZOTERO_DECISIONS'] || File.expand_path('../sources/emerging_philosophy/decisions.jsonl', __dir__)
	IDMAP = ENV['ZOTERO_IDMAP'] || File.expand_path('../sources/emerging_philosophy/regen-idmap.json', __dir__)
	SNAPSHOT = ENV['ZOTERO_SNAPSHOT'] || File.expand_path('../sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json', __dir__)
	SINGLETON_IDS = ENV['ZOTERO_SINGLETON_IDS'] || File.expand_path('../sources/emerging_philosophy/singleton-ids.json', __dir__)
	PRESERVATION_BASELINE = ENV['ZOTERO_PRESERVATION_BASELINE']
	EP001_MEMBERS = %w[EKT6SMX2 PJ6LLK7F 7LCVEML6 IVKJ4VAN].freeze
	EP011_PAIR = %w[27S8UJJA MI6EIDDI].sort.freeze

	module_function

	# Ledger, last-wins per key (per (pair, channel) for gates).
	# @return [Hash] {'gates' => [pair, channel] => gate, ...}
	def load_ledger
		d = { 'gates' => {}, 'anchors' => {}, 'assignments' => {}, 'notes' => {}, 'inventory' => {}, 'retired_anchors' => [] }
		File.readlines(LEDGER).each do |line|
			rec = JSON.parse(line)
			case rec['type']
			when 'gate'
				channel = rec['channel'] || (rec['gate'] == 'part-of' ? 'containment' : 'membership')
				d['gates'][[[rec['a'], rec['b']].sort, channel]] = rec['gate']
			when 'project'
				# name null retires an anchor (cluster dissolved at the gate)
				if rec['name'].nil?
					d['anchors'].delete(rec['key'])
					d['retired_anchors'] |= [rec['key']]
				else
					d['anchors'][rec['key']] = rec['name']
					d['retired_anchors'] -= [rec['key']]
				end
			when 'assignment' then d['assignments'][rec['key']] = rec['value']
			when 'note' then d['notes'][rec['key']] = rec['text']
			when 'inventory' then d['inventory'][rec['id']] = rec
			end
		end
		d
	end

	# All ruling-bearing rows of a sheet, as pair => {'gate' => [...],
	# 'containment' => [...]} — one entry per row copy (mirrors included);
	# nils kept so blank-vs-typed is visible.
	#
	# @param sheet [Hash] parsed review sheet
	# @return [Hash]
	def sheet_rulings(sheet)
		rows = Hash.new { |h, k| h[k] = { 'gate' => [], 'containment' => [] } }
		add = lambda do |a, b, row|
			r = rows[[a, b].sort]
			r['gate'] << row['gate']
			r['containment'] << row['containment']
		end
		(sheet['proposed_clusters'] || []).each do |c|
			(c['edges'] || []).each { |e| add.call(e['a'], e['b'], e) }
			(c['candidate_links'] || []).each { |l| add.call(l['member'], l['other_key'], l) }
		end
		(sheet['singletons'] || []).each do |s|
			(s['candidate_links'] || []).each { |l| add.call(s['key'], l['to'], l) }
		end
		rows
	end

	# Effective cluster membership of a sheet (human assignment edits win;
	# singletons reassigned into clusters included), plus split-out members.
	#
	# @param sheet [Hash]
	# @return [Array(Hash, Hash)] effective (id => [keys]), split (id => [keys])
	def effective_clusters(sheet)
		effective = Hash.new { |h, k| h[k] = [] }
		split = Hash.new { |h, k| h[k] = [] }
		(sheet['proposed_clusters'] || []).each do |c|
			(c['members'] || []).each do |m|
				if m['assignment'].to_s =~ /\AEP-\d+\z/
					effective[m['assignment']] |= [m['key']]
					split[c['id']] |= [m['key']] if m['assignment'] != c['id']
				else
					split[c['id']] |= [m['key']]
				end
			end
		end
		(sheet['singletons'] || []).each do |s|
			effective[s['assignment']] |= [s['key']] if s['assignment'].to_s =~ /\AEP-\d+\z/
		end
		[effective, split]
	end

	# key => v2 cluster id
	def pid_of(sheet)
		p = {}
		(sheet['proposed_clusters'] || []).each { |c| c['members'].each { |m| p[m['key']] = c['id'] } }
		p
	end

	# Mirror-resolved typed value per pair for one field ('gate' or
	# 'containment'): non-'part-of' copies win, like the migration.
	#
	# @param rows [Hash] from sheet_rulings
	# @param field [String]
	# @return [Hash] pair => value
	def resolved(rows, field)
		rows.each_with_object({}) do |(pair, r), out|
			typed = r[field].compact.reject { |g| g.to_s.empty? }
			next if typed.empty?
			out[pair] = typed.reject { |g| g == 'part-of' }.first || typed.first
		end
	end

	# Runs all checks, prints PASS/FAIL per check.
	#
	# @return [void]
	def run
		v1 = YAML.load_file(V1)
		v2 = YAML.load_file(V2)
		ledger = load_ledger
		v2r = sheet_rulings(v2)
		v2pid = pid_of(v2)
		failures = 0

		# ---- check 1: every ledger ruling on its v2 rows (all copies) ----
		bad = []
		ledger['gates'].each do |(pair, channel), gate|
			field = channel == 'membership' ? 'gate' : 'containment'
			rows = v2r[pair]
			if rows.nil? || (rows['gate'].empty? && rows['containment'].empty?)
				bad << "#{pair.join(' <-> ')} (#{channel}): no edge row in v2"
			elsif rows[field].empty? || rows[field].any? { |g| g != gate }
				bad << "#{pair.join(' <-> ')} (#{channel}): ledger #{gate.inspect} but v2 #{field} rows #{rows[field].inspect}"
			end
		end
		if bad.empty?
			puts "PASS 1 — all #{ledger['gates'].size} ledger rulings appear on their v2 edges, both channels (all copies)"
		else
			failures += 1
			puts "FAIL 1 — #{bad.size} ledger rulings not honored:"
			bad.each { |b| puts "       #{b}" }
		end

		# ---- check 2: anchors, cluster cohesion, splits ----
		bad = []
		ledger['anchors'].each_key do |k|
			bad << "anchor #{k} is not in any v2 cluster" unless v2pid.key?(k)
		end
		effective, split = effective_clusters(v1)
		# ledger membership cuts (anything but same-project) authorize separation
		cuts = ledger['gates'].each_with_object({}) do |((pair, channel), gate), h|
			h[pair] = true if channel == 'membership' && gate != 'same-project'
		end
		effective.each do |cid, members|
			next if members.empty?
			members.combination(2) do |a, b|
				next if v2pid[a] && v2pid[a] == v2pid[b]
				pair = [a, b].sort
				bad << "#{cid}: #{a} / #{b} separated with no ledger cut" unless cuts[pair]
			end
			bad << "#{cid}: no member lands in any v2 cluster" if members.none? { |k| v2pid[k] } && (members & ledger['retired_anchors']).empty?
		end
		v1r = sheet_rulings(v1)
		v1membership = resolved(v1r, 'gate').reject { |pair, g| g == 'part-of' || ZoteroMigrateDecisions::CONTAINMENT_CORRECTIONS.include?(pair) }
		split.each do |cid, keys|
			retained = effective[cid]
			next if retained.empty?
			keys.each do |k|
				next unless v1membership.any? { |pair, g| pair.include?(k) && retained.include?(pair.find { |x| x != k } || k) && %w[describes unrelated].include?(g) }
				clash = retained.select { |r| v2pid[k] && v2pid[k] == v2pid[r] }
				bad << "split item #{k} (ex-#{cid}) still clustered with #{clash.join(',')}" unless clash.empty?
			end
		end
		if bad.empty?
			puts "PASS 2 — #{ledger['anchors'].size} anchors are v2 clusters; migrated clusters cohesive; split items separated"
		else
			failures += 1
			puts "FAIL 2 — #{bad.size} cohesion/anchor/split problems:"
			bad.each { |b| puts "       #{b}" }
		end

		# ---- check 3: EP-001 holds all four members ----
		cid = v2pid['EKT6SMX2']
		members = (v2['proposed_clusters'].find { |c| c['id'] == cid } || { 'members' => [] })['members'].map { |m| m['key'] }
		missing = EP001_MEMBERS - members
		if cid && missing.empty?
			puts "PASS 3 — old EP-001 = v2 #{cid}, contains all four of #{EP001_MEMBERS.join(', ')}"
		else
			failures += 1
			puts "FAIL 3 — v2 cluster for EKT6SMX2 is #{cid.inspect}, missing #{missing.join(', ')}"
		end

		# ---- check 4: ruling maps v1 vs v2, per channel ----
		# v1 membership: resolved non-part-of gates minus the containment
		# corrections; v1 containment: resolved part-of plus the corrections
		# (value unrelated). v2: `gate` is ledger-membership only;
		# `containment` is ledger-containment or a pre-typed
		# contained-in-book default.
		v1mem = v1membership
		v1con = resolved(v1r, 'gate').select { |pair, g| g == 'part-of' }
		ZoteroMigrateDecisions::CONTAINMENT_CORRECTIONS.each do |pair|
			v1con[pair] = 'unrelated' if resolved(v1r, 'gate').key?(pair)
		end
		v2mem = resolved(v2r, 'gate')
		v2con = resolved(v2r, 'containment')
		lost_mem = v1mem.reject { |pair, g| v2mem[pair] == g }
		lost_con = v1con.reject { |pair, g| v2con[pair] == g }
		ledger_mem = {}
		ledger_con = {}
		ledger['gates'].each { |(pair, channel), g| (channel == 'membership' ? ledger_mem : ledger_con)[pair] = g }
		unexplained_mem = v2mem.reject { |pair, g| ledger_mem[pair] == g }
		unexplained_con = v2con.reject do |pair, g|
			ledger_con[pair] == g || (g == 'part-of' && v2r[pair] && v2r[pair]['gate'].any? && v2_detail(v2, pair).include?('contained-in-book'))
		end
		if lost_mem.empty? && lost_con.empty? && unexplained_mem.empty? && unexplained_con.empty?
			puts "PASS 4 — ruling maps preserved: membership #{v1mem.size} v1 -> #{v2mem.size} v2, " \
				"containment #{v1con.size} v1 -> #{v2con.size} v2 " \
				"(#{(v2con.keys - v1con.keys).size} containment gained, all ledger/pre-gate explained)"
		else
			failures += 1
			puts "FAIL 4 — ruling drift: lost membership #{lost_mem.inspect}, lost containment #{lost_con.inspect}, " \
				"unexplained v2 membership #{unexplained_mem.inspect}, unexplained v2 containment #{unexplained_con.keys.inspect}"
		end

		# ---- check 5: id map written and sane ----
		bad = []
		begin
			map = JSON.parse(File.read(IDMAP))
			o2n = map['old_to_new'] || {}
			bad << "EP-001 has no mapping" unless o2n['EP-001']
			bad << "EP-004 not retired" unless (map['retired'] || []).include?('EP-004')
			if o2n['EP-001']
				c = v2['proposed_clusters'].find { |x| x['id'] == o2n['EP-001'] }
				bad << "EP-001 maps to #{o2n['EP-001']} which is not a v2 cluster" if c.nil?
				if c
					miss = EP001_MEMBERS - c['members'].map { |m| m['key'] }
					bad << "EP-001 -> #{o2n['EP-001']} missing members #{miss.join(',')}" unless miss.empty?
				end
			end
			o2n.each do |oid, nid|
				bad << "mapped id #{nid} (from #{oid}) not a v2 cluster" unless v2['proposed_clusters'].any? { |c| c['id'] == nid }
			end
			v2ids = v2['proposed_clusters'].map { |c| c['id'] }
			bad << "'new' lists ids that are not v2 clusters: #{(map['new'] - v2ids).inspect}" unless (map['new'] - v2ids).empty?
			bad << "v2 clusters unaccounted for by map: #{(v2ids - o2n.values - map['new']).inspect}" unless (v2ids - o2n.values - map['new']).empty?
		rescue Errno::ENOENT, JSON::ParserError => e
			bad << "idmap unreadable: #{e.message}"
		end
		if bad.empty?
			puts "PASS 5 — regen-idmap.json sane: EP-001 -> #{map['old_to_new']['EP-001']} (same 4 members), " \
				"retired #{map['retired'].inspect}, new #{map['new'].inspect}"
		else
			failures += 1
			puts "FAIL 5 — idmap problems:"
			bad.each { |b| puts "       #{b}" }
		end

		# ---- check 6: two-channel spot checks ----
		bad = []
		ep011 = v2r[EP011_PAIR]
		if ep011.nil?
			bad << "EP-011 pair #{EP011_PAIR.join(' <-> ')} has no v2 row"
		else
			bad << "EP-011 pair membership rows #{ep011['gate'].inspect} (want all 'same-project')" unless ep011['gate'].any? && ep011['gate'].all? { |g| g == 'same-project' }
			bad << "EP-011 pair containment rows #{ep011['containment'].inspect} (want all 'part-of')" unless ep011['containment'].any? && ep011['containment'].all? { |g| g == 'part-of' }
		end
		ids = EP011_PAIR.map { |k| v2pid[k] }.uniq
		bad << "EP-011 pair not in one v2 cluster: #{ids.inspect}" unless ids.size == 1 && !ids.first.nil?
		ZoteroMigrateDecisions::CONTAINMENT_CORRECTIONS.each do |pair|
			r = v2r[pair]
			if r.nil?
				bad << "#{pair.join(' <-> ')} has no v2 row"
			else
				bad << "#{pair.join(' <-> ')} membership not blank: #{r['gate'].inspect}" unless r['gate'].all? { |g| g.to_s.empty? }
				bad << "#{pair.join(' <-> ')} containment rows #{r['containment'].inspect} (want all 'unrelated')" unless r['containment'].any? && r['containment'].all? { |g| g == 'unrelated' }
			end
		end
		if bad.empty?
			puts "PASS 6 — EP-011 intro<->issue: membership same-project + containment part-of on one cluster; " \
				"LFP7FHS2 sister-volume pairs: containment unrelated, membership blank"
		else
			failures += 1
			puts "FAIL 6 — two-channel spot checks:"
			bad.each { |b| puts "       #{b}" }
		end

		# ---- check 7: population, cross-reference, and inventory invariants ----
		bad = []
		anchored = v2.fetch('proposed_clusters', [])
		singletons = v2.fetch('singletons', [])
		complexes = anchored.select { |unit| unit['grouping'] == 'complex' }
		anchored_singletons = anchored.select { |unit| unit['grouping'] == 'singleton' }
		bad << "complex/singleton labels disagree with member counts" if complexes.any? { |unit| unit['members'].size < 2 } || anchored_singletons.any? { |unit| unit['members'].size != 1 }
		assigned = anchored.flat_map { |unit| unit['members'].map { |member| member['key'] } } + singletons.map { |row| row['key'] } + v2.fetch('non_project', []).map { |row| row['key'] }
		begin
			snapshot = JSON.parse(File.read(SNAPSHOT))
			population = snapshot.fetch('items').reject { |item| %w[attachment note].include?(item.dig('data', 'itemType')) }.map { |item| item.fetch('key') }.sort
			bad << "assigned population keys differ from frozen snapshot" unless assigned.sort == population
		rescue Errno::ENOENT, JSON::ParserError, KeyError => e
			bad << "snapshot population unreadable: #{e.message}"
		end
		audit_units = anchored + singletons
		unit_ids = audit_units.map { |unit| unit['id'] }
		bad << "duplicate audit-unit EP IDs: #{ZoteroSingletonIds.duplicates(unit_ids).join(', ')}" unless unit_ids.uniq.size == unit_ids.size
		key_to_id = {}
		anchored.each { |unit| unit['members'].each { |member| key_to_id[member['key']] = unit['id'] } }
		singletons.each { |row| key_to_id[row['key']] = row['id'] }
		anchored.each do |unit|
			unit.fetch('candidate_links', []).each do |link|
				expected = key_to_id[link['other_key']]
				bad << "incorrect EP target for #{link['other_key']}: #{link['to_project'].inspect}, expected #{expected.inspect}" unless link['to_project'] == expected
			end
		end
		singletons.each do |row|
			row.fetch('candidate_links', []).each do |link|
				expected = key_to_id[link['to']]
				bad << "incorrect EP target for #{link['to']}: #{link['to_project'].inspect}, expected #{expected.inspect}" unless link['to_project'] == expected
			end
		end
		bad << "an audit unit lacks an inventory" if audit_units.any? { |unit| !unit['inventory'].is_a?(Array) }
		entries_by_id = {}
		artifact_ids = []
		audit_units.each do |unit|
			unit.fetch('inventory', []).each do |entry|
				valid = entry['id'].is_a?(String) && entry['id'].match?(/\AEP-\d{3,}\/.+\z/) &&
					%w[required optional unknown].include?(entry['requirement']) && [true, false].include?(entry['proposed']) && entry['basis'].is_a?(String)
				bad << "invalid inventory entry in #{unit['id']}: #{entry.inspect}" unless valid
				entries_by_id[entry['id']] = entry
				artifact_ids << entry['id']
			end
		end
		bad << "duplicate artifact IDs: #{ZoteroSingletonIds.duplicates(artifact_ids).join(', ')}" unless artifact_ids.uniq.size == artifact_ids.size
		ledger['inventory'].each do |artifact_id, ruling|
			entry = entries_by_id[artifact_id]
			if ruling['requirement'] == 'not-expected'
				bad << "not-expected artifact remains present: #{artifact_id}" if entry
			elsif entry.nil? || entry['requirement'] != ruling['requirement'] || entry['proposed'] != false
				bad << "inventory ruling not honored: #{artifact_id}"
			end
		end
		singletons.each do |row|
			expected = row['inventory'].any? { |entry| entry['requirement'] == 'unknown' } ? ['inventory contains unknowns — set at gate'] : []
			bad << "incorrect NEEDS-YOU flags for #{row['key']}" unless row['needs_you'] == expected
		end
		begin
			registry = ZoteroSingletonIds.load(SINGLETON_IDS)
			current_keys = singletons.map { |row| row['key'] }
			active = registry.select { |record| current_keys.include?(record['key']) }
			expected = singletons.map { |row| { 'key' => row['key'], 'id' => row['id'] } }.sort_by { |record| record['key'] }
			bad << "active singleton registry differs from sheet" unless active == expected
			id_map = JSON.parse(File.read(IDMAP))
			mappings = id_map.fetch('old_to_new', {})
			reserved = anchored.map { |unit| unit['id'] } + v2.fetch('id_log', []).map { |entry| entry['id'] } + mappings.keys + mappings.values + id_map.fetch('retired', []) + id_map.fetch('new', [])
			registry_by_key = registry.each_with_object({}) { |record, by_key| by_key[record['key']] = record['id'] }
			allowed = anchored.select { |unit| unit['members'].size == 1 }.map { |unit| registry_by_key[unit['members'].first['key']] }.compact
			collisions = registry.map { |record| record['id'] } & (reserved.compact - allowed)
			bad << "singleton registry reuses active/retired IDs: #{collisions.join(', ')}" unless collisions.empty?
		rescue Errno::ENOENT, JSON::ParserError, RuntimeError => e
			bad << "singleton registry invalid: #{e.message}"
		end
		complex_items = complexes.sum { |unit| unit['members'].size }
		expected_stats = { 'complexes' => complexes.size, 'complex_items' => complex_items, 'anchored_singletons' => anchored_singletons.size,
			'unanchored_singletons' => singletons.size, 'singletons' => anchored_singletons.size + singletons.size,
			'audit_units' => audit_units.size, 'non_project' => v2.fetch('non_project', []).size }
		expected_stats.each { |key, value| bad << "statistics #{key}=#{v2.dig('statistics', key).inspect}, expected #{value}" unless v2.dig('statistics', key) == value }
		if bad.empty?
			puts "PASS 7 — population keys, EP targets, EP/artifact IDs, registry, inventory structure/rulings, and flags valid"
		else
			failures += 1
			puts "FAIL 7 — complex/singleton/inventory problems:"
			bad.each { |problem| puts "       #{problem}" }
		end

		if PRESERVATION_BASELINE
			bad = []
			begin
				baseline = YAML.load_file(PRESERVATION_BASELINE)
				baseline_units = (baseline.fetch('proposed_clusters', []) + baseline.fetch('singletons', [])).each_with_object({}) { |unit, by_id| by_id[unit['id']] = unit }
				current_units = audit_units.each_with_object({}) { |unit, by_id| by_id[unit['id']] = unit }
				baseline_units.each do |id, old_unit|
					new_unit = current_units[id]
					bad << "audit unit #{id} is missing" unless new_unit
					next unless new_unit
					expected_inventory = old_unit.fetch('inventory', []).each_with_object([]) do |entry, derived|
						ruling = ledger['inventory'][entry['id']]
						if ruling.nil?
							derived << entry
						elsif ruling['requirement'] != 'not-expected'
							confirmed = entry.merge('requirement' => ruling['requirement'], 'proposed' => false)
							%w[date note evidence].each { |field| confirmed[field] = ruling[field] if ruling.key?(field) }
							derived << confirmed
						end
					end
					ledger['inventory'].each do |artifact_id, ruling|
						next unless artifact_id.start_with?("#{id}/") && expected_inventory.none? { |entry| entry['id'] == artifact_id }
						next if ruling['requirement'] == 'not-expected'
						if ruling['basis'].to_s.empty?
							bad << "new artifact lacks basis: #{artifact_id}"
							next
						end
						entry = { 'id' => artifact_id, 'requirement' => ruling['requirement'], 'proposed' => false, 'basis' => ruling['basis'] }
						%w[date note evidence].each { |field| entry[field] = ruling[field] if ruling.key?(field) }
						expected_inventory << entry
					end
					bad << "unauthorized inventory change in #{id}" unless expected_inventory == new_unit['inventory']
					old_links = old_unit.fetch('candidate_links', [])
					new_links = new_unit.fetch('candidate_links', [])
					without_targets = lambda { |links| links.map { |link| link.reject { |key, _| key == 'to_project' } } }
					bad << "candidate links changed in #{id}" unless without_targets.call(old_links) == without_targets.call(new_links)
					old_targets = old_links.map { |link| link['to_project'] }.compact
					new_targets = new_links.map { |link| link['to_project'] }.compact
					bad << "existing EP targets changed in #{id}" unless (old_targets - new_targets).empty?
				end
			rescue Errno::ENOENT, Psych::SyntaxError => e
				bad << "preservation baseline unreadable: #{e.message}"
			end
			if bad.empty?
				puts "PASS 8 — preservation baseline honored; only ledger-authorized inventory changes"
			else
				failures += 1
				puts "FAIL 8 — preservation problems:"
				bad.each { |problem| puts "       #{problem}" }
			end
		end

		puts failures.zero? ? 'ALL CHECKS PASSED' : "#{failures} CHECK(S) FAILED"
		exit(failures.zero? ? 0 : 1)
	end

	# Detail string of a pair's first v2 row (for pre-gate provenance).
	def v2_detail(v2, pair)
		(v2['proposed_clusters'] || []).each do |c|
			(c['edges'] || []).each { |e| return e['detail'].to_s if [e['a'], e['b']].sort == pair }
			(c['candidate_links'] || []).each { |l| return l['detail'].to_s if [l['member'], l['other_key']].sort == pair }
		end
		(v2['singletons'] || []).each do |s|
			(s['candidate_links'] || []).each { |l| return l['detail'].to_s if [s['key'], l['to']].sort == pair }
		end
		''
	end
end

ZoteroVerifyDecisions.run if __FILE__ == $PROGRAM_NAME
