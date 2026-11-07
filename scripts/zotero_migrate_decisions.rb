#!/usr/bin/env ruby
# == Decisions Ledger Migration
#
# One-off migration: harvests the human gate decisions typed into
# review-sheet-v1.yaml and writes the initial decisions.jsonl ledger, so
# that regenerating the review sheet (scripts/zotero_cluster.rb) no longer
# wipes them. EP IDs never appear in the ledger — edge identity is the
# UNORDERED pair of Zotero item keys.
#
# == What is harvested
# * +gate+       - every non-blank gate on cluster edges, cluster
#                  candidate_links and singleton candidate_links, sorted
#                  into the two orthogonal ruling channels (§3 of the
#                  ontology vision): +part-of+ is a CONTAINMENT ruling
#                  (partOfDocument); all other values are MEMBERSHIP
#                  rulings (sameProjectAs and its negations). The v1-era
#                  "retype part-of -> unrelated" corrections
#                  (CONTAINMENT_CORRECTIONS) are containment rulings with
#                  value +unrelated+ — they reject the proposed containment
#                  and leave membership blank. Mirror copies (the same edge
#                  surfaced from both endpoints) are deduped to ONE record
#                  per (unordered pair, channel); disagreeing copies print
#                  a warning and the non-'part-of' value wins.
# * +assignment+ - non_project entries a human confirmed
#                  (assignment 'non-project' AND needs_you false); generator
#                  proposals (needs_you true) are left unrecorded.
# * +project+    - project anchors: for every cluster whose effective
#                  members (honouring human +assignment:+ edits, including
#                  singletons reassigned into the cluster) would NOT form a
#                  connected component under the confirmed same-project
#                  gates alone — all one-member clusters included — an
#                  anchor for the cluster's lowest item key.
# * bridging membership +same-project+ gates - when a cluster's effective
#   members split into >1 component under the confirmed same-project
#   gates, bridge records between the lowest keys of adjacent components
#   (note "merge weld from migration") so the cluster holds together under
#   decision-resolved clustering. This covers sub-groups merged by
#   assignment with no same-project edge typed between them (e.g. EP-001:
#   EKT6SMX2/PJ6LLK7F plus 7LCVEML6/IVKJ4VAN from the retired EP-004).
#   Bridges are membership rulings; a containment ruling on the same pair
#   (e.g. EP-011's part-of) coexists — the channels are orthogonal.
#
# All migrated records are dated MIGRATION_DATE with note "migrated from
# review-sheet-v1" (bridges carry their own note). The script is
# idempotent: it rewrites the migrated ledger wholesale, appending the
# EP-011 containment postscript (POSTSCRIPT) last so its richer note wins.
#
# == Usage
#   bin/bundle exec ruby scripts/zotero_migrate_decisions.rb
#
require 'json'
require 'yaml'
require 'set'

module ZoteroMigrateDecisions
	SHEET = File.expand_path('../sources/emerging_philosophy/review-sheet-v1.yaml', __dir__)
	LEDGER = File.expand_path('../sources/emerging_philosophy/decisions.jsonl', __dir__)
	MIGRATION_DATE = '2026-10-20'
	MEMBERSHIP_VALUES = %w[same-project describes implements cites unrelated].freeze
	CONTAINMENT_VALUES = %w[part-of unrelated].freeze

	# v1-era "retype part-of -> unrelated" corrections: the human rejected
	# the proposed containment (container contained-in-book), not the
	# membership — these pairs carry a containment +unrelated+ ruling and
	# stay blank on the membership channel.
	CONTAINMENT_CORRECTIONS = [%w[3VEBTE69 LFP7FHS2], %w[I7MAW4IQ LFP7FHS2]].map(&:sort).freeze

	# Appended last so its note wins for (pair, containment): EP-011's
	# containment ruling is orthogonal to the membership merge weld on the
	# same pair (the human ruled the special issue a single project AND the
	# introduction contained in it).
	POSTSCRIPT = [
		{ 'type' => 'gate', 'a' => '27S8UJJA', 'b' => 'MI6EIDDI', 'gate' => 'part-of',
			'channel' => 'containment', 'date' => MIGRATION_DATE,
			'note' => "guest editors' introduction (pp. 181-183) contained in the issue; orthogonal to membership ruling" }
	].freeze

	module_function

	# Runs the migration, writes the ledger, prints the summary.
	#
	# @return [void]
	def run
		sheet = YAML.load_file(SHEET)
		warnings = []

		# ==== gates: one record per (unordered pair, channel) ===============
		# Mirrors deduped per channel. Channel: part-of is containment; the
		# named CONTAINMENT_CORRECTIONS retypes are containment too; all
		# other values are membership.
		gates = {}
		harvest = lambda do |a, b, gate, where|
			return if gate.nil? || gate.to_s.strip.empty?
			gate = gate.to_s.strip
			pair = [a, b].sort
			channel = (gate == 'part-of' || (gate == 'unrelated' && CONTAINMENT_CORRECTIONS.include?(pair))) ? 'containment' : 'membership'
			unless (channel == 'containment' ? CONTAINMENT_VALUES : MEMBERSHIP_VALUES).include?(gate)
				warnings << "unknown #{channel} gate value #{gate.inspect} on #{pair.join(' <-> ')} (#{where})"
			end
			key = [pair, channel]
			if gates.key?(key) && gates[key] != gate
				warnings << "mirror disagreement on #{pair.join(' <-> ')} (#{channel}): #{gates[key].inspect} vs #{gate.inspect} — keeping #{[gates[key], gate].reject { |g| g == 'part-of' }.first || gates[key]}"
				keep = [gates[key], gate].reject { |g| g == 'part-of' }
				gates[key] = keep.first || gates[key]
			else
				gates[key] = gate
			end
		end
		(sheet['proposed_clusters'] || []).each do |c|
			(c['edges'] || []).each { |e| harvest.call(e['a'], e['b'], e['gate'], "cluster #{c['id']} edges") }
			(c['candidate_links'] || []).each { |l| harvest.call(l['member'], l['other_key'], l['gate'], "cluster #{c['id']} candidate_links") }
		end
		(sheet['singletons'] || []).each do |s|
			(s['candidate_links'] || []).each { |l| harvest.call(s['key'], l['to'], l['gate'], "singleton #{s['key']} candidate_links") }
		end

		# ==== effective cluster membership (human assignment edits win) ====
		effective = Hash.new { |h, k| h[k] = [] }
		split_out = Hash.new { |h, k| h[k] = [] }
		(sheet['proposed_clusters'] || []).each do |c|
			(c['members'] || []).each do |m|
				if m['assignment'].to_s =~ /\AEP-\d+\z/
					# assignment to another cluster id is a human merge into it
					# (e.g. EP-004's members reassigned to EP-001)
					effective[m['assignment']] |= [m['key']]
					split_out[c['id']] |= [m['key']] if m['assignment'] != c['id']
				else
					split_out[c['id']] |= [m['key']]
				end
			end
		end
		(sheet['singletons'] || []).each do |s|
			effective[s['assignment']] |= [s['key']] if s['assignment'].to_s =~ /\AEP-\d+\z/
		end

		# ==== project anchors + merge-weld bridges =========================
		# Gate records are written FIRST: in the append-only ledger, last-wins
		# per (pair, channel), so a membership bridge then overrides a
		# conflicting human-typed MEMBERSHIP gate on the same pair (kept
		# assignment wins). Containment rulings on the same pair coexist —
		# the channels are orthogonal.
		records = []
		gates.sort_by { |(pair, channel), _| [pair, channel] }.each do |((a, b), channel), gate|
			records << { 'type' => 'gate', 'a' => a, 'b' => b, 'gate' => gate, 'channel' => channel,
				'date' => MIGRATION_DATE, 'note' => 'migrated from review-sheet-v1' }
		end

		anchors = 0
		bridges = 0
		effective.keys.sort.each do |cid|
			members = effective[cid].sort
			next if members.empty?
			# components over this cluster's confirmed same-project gates
			parent = members.to_h { |k| [k, k] }
			find = lambda do |x|
				root = x
				root = parent[root] while parent[root] != root
				root
			end
			gates.each do |((a, b), channel), g|
				next unless channel == 'membership' && g == 'same-project' && parent.key?(a) && parent.key?(b)
				ra, rb = find.call(a), find.call(b)
				parent[rb] = ra unless ra == rb
			end
			comp = Hash.new { |h, k| h[k] = [] }
			members.each { |k| comp[find.call(k)] << k }
			components = comp.values.map(&:sort).sort_by(&:first)
			if components.size > 1
				components.each_cons(2) do |x, y|
					pair = [x.first, y.first].sort
					if gates.key?([pair, 'membership'])
						warnings << "cluster #{cid}: merge weld #{pair.join(' <-> ')} OVERRIDES human-typed membership gate " \
							"#{gates[[pair, 'membership']].inspect} on the same pair (kept assignment wins)"
					end
					warnings << "cluster #{cid}: members split into #{components.size} components under confirmed " \
						"same-project gates — bridging #{pair.join(' <-> ')}"
					records << { 'type' => 'gate', 'a' => pair.first, 'b' => pair.last, 'gate' => 'same-project',
						'channel' => 'membership', 'date' => MIGRATION_DATE, 'note' => 'merge weld from migration' }
					bridges += 1
				end
			end
			unless components.size == 1 && members.size > 1
				name = (sheet['proposed_clusters'].find { |c| c['id'] == cid } || {})['proposed_name']
				records << { 'type' => 'project', 'key' => members.first, 'name' => name, 'date' => MIGRATION_DATE }
				anchors += 1
			end
		end

		# ==== assignments: human-confirmed non-project only ================
		assignments = 0
		(sheet['non_project'] || []).each do |n|
			next unless n['assignment'] == 'non-project' && n['needs_you'] == false
			records << { 'type' => 'assignment', 'key' => n['key'], 'value' => 'non-project', 'date' => MIGRATION_DATE }
			assignments += 1
		end

		# ==== postscript: hand-authored rulings appended last (last-wins) ====
		records.concat(POSTSCRIPT)

		File.write(LEDGER, records.map { |r| JSON.generate(r) }.join("\n") + "\n")

		by_channel = gates.each_with_object(Hash.new(0)) { |((_, ch), _), h| h[ch] += 1 }.sort.to_h
		puts "wrote #{records.size} records to #{LEDGER}"
		puts "  gates: #{gates.size} harvested (#{by_channel}) + #{bridges} membership merge-weld bridges + #{POSTSCRIPT.size} postscript"
		puts "  project anchors: #{anchors}"
		puts "  assignments: #{assignments}"
		puts "  notes: 0 (none harvested)"
		puts "effective clusters: #{effective.size} (#{effective.map { |cid, m| "#{cid}=#{m.size}" }.join(', ')})"
		split_out.each { |cid, ks| puts "  split out of #{cid}: #{ks.sort.join(', ')}" }
		puts "warnings: #{warnings.size}"
		warnings.each { |w| puts "  WARNING: #{w}" }
	end
end

ZoteroMigrateDecisions.run if __FILE__ == $PROGRAM_NAME
