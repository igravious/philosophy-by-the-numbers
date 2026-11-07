#!/usr/bin/env ruby
# == Phase 1 — Record Clustering Review Sheet
#
# Builds the record-clustering review sheet for the "emerging philosophy"
# source audit (docs/ep/emerging-philosophy-audit-plan.md §4) from the frozen
# Phase 0 snapshot. OFFLINE: reads the snapshot JSON only, no API calls.
#
# Population: the snapshot's top-level items (non-attachment, non-note).
# Orphan count is asserted from the snapshot's verification metadata.
#
# == Candidate edges (§2.3), all proposals with type + confidence
# * +related-link+        - dc:relation URIs pointing into the population
#                           (none exist in this snapshot; extractor kept)
# * +shared-tag+          - identical data.tags[].tag; tags borne by >5 items
#                           suppressed as noisy
# * +title-overlap+       - token Jaccard (downcased, stopword-filtered,
#                           philosoph*-aliased, plural-stripped); j >= 0.65
#                           high unless all shared tokens are common-topic
#                           (df > 10); 0.4 <= j < 0.65 medium, lifted to high
#                           when a shared token is distinctive (df <= 3)
# * +container+           - STRUCTURAL, never clustering-eligible: the user's
#                           container convention (bookSection/conferencePaper
#                           bookTitle/proceedingsTitle <-> book items, detail
#                           'contained-in-book', pre-typed +part-of+ at the
#                           gate) and chapter cliques (same-volume context)
# * +shared-identifier+   - same non-generic host (+shared
#                           non-generic first path segment); title token
#                           (df <= 2) matching another item's host label
#                           (len >= 6, or len >= 3 with a digit as label
#                           prefix); shared non-generic host label across
#                           hosts; DOI identity / DOI-in-URL / shared DOI stem;
#                           creator full name (forename+surname, adjacent
#                           tokens; name:SURNAME_forename) in another item's
#                           abstract/extra text
# * +creator-year+        - shared creator surname with |year delta| <= 2;
#                           per spec ALWAYS low confidence
#
# Confidence: low < medium < high. Promotion to high: (a) two distinct
# promotion-eligible medium+ evidence types (doi-stem, single-distinctive-
# token and common-topic-only mediums are NOT eligible), or (b) medium
# title-overlap corroborated by a creator-year edge.
#
# == Clustering
# Connected components over HIGH edges only (documented threshold;
# precision over recall). Container edges are structural (the user's
# bookTitle<->book convention) and NEVER weld complexes, nor do creator-year
# edges; medium/low edges are recorded as candidate_links
# (cross-references between audit units use EP IDs per §2.1).
#
# == Decisions ledger (decisions.jsonl)
# Append-only JSONL, one object per line, last-wins per key; human gate
# decisions survive sheet regeneration. Edge identity is the UNORDERED pair
# of Zotero item keys; inventory rulings use stable artifact IDs.
#
# TWO-CHANNEL ruling model (docs/ep/emerging-philosophy-ontology-vision.md
# §3): membership (sameComplexAs and its negations) and containment
# (partOfDocument) are ORTHOGONAL relations. Every pair can carry one
# ruling per channel, independently; last-wins is per (pair, channel).
# * {"type":"gate","a":K,"b":K,"gate":G,"channel":"membership"|"containment",...}
#   membership: same-project (legacy value; welds complexes) | describes |
#   implements | cites | unrelated | siblings (each cuts, even on high evidence).
#   containment: part-of | unrelated — NEVER welds and never cuts; it only
#   feeds the sheet's +containment:+ display field (overriding the
#   +pre_gate+ part-of default). Pairs with no evidence edge get a
#   synthesized 'decision' edge (membership: confidence high, so merge
#   welds can bridge items with no shared evidence; containment:
#   confidence low, so the evidence rule never welds on them). A membership
#   ruling overrides the sheet row's +gate:+; a containment ruling (or, in
#   its absence, +pre_gate+) supplies the row's +containment:+ field.
#   A {"type":"project",...,"name":null} record retires an audit-unit anchor
#   (complex dissolved at the gate).
# * {"type":"assignment","key":K,"value":"non-project"|"unresolved",...}
#   Forces an item into the non_project section (needs_you false) or back to
#   singletons; absence means generator default.
# * {"type":"project","key":K,"name":"...",...} - legacy audit-unit anchor:
#   the item retains an EP ID even with no welding edges (splits can leave
#   anchored singletons); emitted as a one-member proposed_cluster when it
#   would otherwise be unanchored.
# * {"type":"note","key":K,"text":"...",...} - annotation surfaced on the
#   item's sheet row as a +note:+ field.
# * {"type":"inventory","id":"EP-###/...","requirement":"required|optional|not-expected",...}
#   Confirms a proposed artifact (proposed false) or removes it as not-expected.
#
# == ID remap
# When PREV_SHEET exists (and differs from the output), the old sheet's
# cluster member-sets (effective, i.e. honouring human +assignment:+ edits)
# are matched against the new complexes; the old->new map is written to
# regen-idmap.json and the old sheet's id_log is carried forward, appending
# entries for IDs retired by this regen.
#
# == Outputs (deterministic: identical snapshot + ledger + ID registries -> identical sheets)
# * sources/emerging_philosophy/review-sheet-v1.yaml - machine sheet
# * sources/emerging_philosophy/review-sheet-v1.md   - human companion
# Output paths are overridable via ZOTERO_SHEET_YAML / ZOTERO_SHEET_MD (used
# for non-destructive regeneration checks, e.g. review-sheet-v2).
#
# == Usage
#   bin/bundle exec ruby scripts/zotero_cluster.rb
#   ZOTERO_SHEET_YAML=.../review-sheet-v2.yaml ZOTERO_SHEET_MD=.../review-sheet-v2.md \
#     bin/bundle exec ruby scripts/zotero_cluster.rb
#
require 'json'
require 'yaml'
require 'uri'
require 'digest'
require 'set'
require 'date'
require_relative 'zotero_singleton_ids'

module ZoteroCluster
	SNAPSHOT = ENV['ZOTERO_SNAPSHOT'] || File.expand_path('../sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json', __dir__)
	OUT_YAML = ENV['ZOTERO_SHEET_YAML'] || File.expand_path('../sources/emerging_philosophy/review-sheet-v1.yaml', __dir__)
	OUT_MD = ENV['ZOTERO_SHEET_MD'] || File.expand_path('../sources/emerging_philosophy/review-sheet-v1.md', __dir__)
	DECISIONS = ENV['ZOTERO_DECISIONS'] || File.expand_path('../sources/emerging_philosophy/decisions.jsonl', __dir__)
	PREV_SHEET = ENV['ZOTERO_PREV_SHEET'] || File.expand_path('../sources/emerging_philosophy/review-sheet-v1.yaml', __dir__)
	IDENTITY_SHEET = ENV['ZOTERO_IDENTITY_SHEET'] || OUT_YAML
	IDMAP = ENV['ZOTERO_IDMAP'] || File.expand_path('../sources/emerging_philosophy/regen-idmap.json', __dir__)
	SINGLETON_IDS = ENV['ZOTERO_SINGLETON_IDS'] || File.expand_path('../sources/emerging_philosophy/singleton-ids.json', __dir__)
	SHEET_NAME = File.basename(OUT_YAML, '.yaml')

	# Calibration pairs (§4.1): known true pairs that must surface as edges.
	CALIBRATION = [
		['Digital Ricoeur <-> context paper', '4WGFYP6Y', 'PL246G6Y'],
		['Digital Ricoeur <-> data model paper', '4WGFYP6Y', '8ZZAKGN4'],
		['Proof Designer (Bedau & Moor) <-> PROOF DESIGNER workbench paper', 'LYZJNKEZ', '9PVXVXNY'],
		['PDC ontology <-> Foundations of an Ontology of Philosophy', '9MMPB8CE', 'FPK48QJ3'],
		['History of Philosophy site <-> README', 'REGDYTQX', 'AMNRSRJF'],
		['Zoomable Graph site <-> reddit post', 'EK7B5CUW', '76JX3CTF']
	].freeze

	STOPWORDS = %w[
		the a an of and or in on for to with by from as at is are was were be been its it this that these those
		towards toward vs via how what why when where which who whom into about between through using use used based
		some all more most other others such no not nor so if then than too very can will just should could would may
		might must shall do does did have has had having but over after before under out up off again once here there
		we you your he she they them his her their our my him us new oc r dataisbeautiful am pm
	].freeze
	ALIASES = {
		'philosophy' => 'philosoph', 'philosophers' => 'philosoph', 'philosopher' => 'philosoph',
		'philosophical' => 'philosoph', 'philosophies' => 'philosoph', 'philosophie' => 'philosoph'
	}.freeze

	# Generic platform/publisher hosts: no host-based edges (they carry many
	# unrelated projects). Matching is on the full hostname (subdomains of a
	# platform remain distinct, e.g. dr2blog.hcommons.org).
	GENERIC_HOSTS = %w[
		reddit.com openculture.com dailynous.com huffingtonpost.com youtube.com github.com gitlab.com jstor.org
		doi.org degruyter.com link.springer.com springer.com onlinelibrary.wiley.com wiley.com philpapers.org
		researchgate.net academic.oup.com cambridge.org bloomsburycollections.com ieeexplore.ieee.org portal.acm.org
		doi.acm.org dl.acm.org plato.stanford.edu en.wikipedia.org wikipedia.org wikidata.org zenodo.org
		linkinghub.elsevier.com iris.unito.it dharchive.org hcommons.org nature.com czasopisma.uni.lodz.pl
	].freeze

	# Generic first URL path segments that never signal a project.
	GENERIC_SEGMENTS = (%w[
		blog group ftp pubs publications papers projects project research files file documents wp-content index home
		about software code entries archive item items view page pages node content docs doc download downloads
		resources media
	] + (1970..2029).map(&:to_s)).freeze

	# Host labels that identify institutions/platforms, not projects.
	TLD_LABELS = %w[com org net edu gov ac uk io ca us de fr eu info it nl].freeze
	GENERIC_LABELS = %w[
		www blog blogs home main site web new my me stanford wikipedia wikidata academic oxford cambridge harvard
		mit oup wiley springer degruyter nature elsevier ieee acm jstor zenodo reddit youtube huffingtonpost
		openculture dailynous philpapers researchgate bloomsbury wordpress github gitlab hcommons
	].freeze

	TAG_MAX_BEARERS = 5       # shared-tag: suppress tags borne by more items
	TITLE_DF_DISTINCTIVE = 3  # title token document-frequency ceiling for "distinctive"
	TITLE_DF_COMMON = 10      # shared tokens above this df are common-topic
	JACCARD_HIGH = 0.65
	JACCARD_MEDIUM = 0.4
	CREATOR_YEAR_WINDOW = 2   # |year delta| for creator-year edges
	LARGE_CLUSTER = 10        # NEEDS-YOU flag at/above this size

	CONFIDENCE = { 'low' => 0, 'medium' => 1, 'high' => 2 }.freeze

	# §2.1 role proposals from itemType (+URL patterns), each with confidence.
	ROLE_MAP = {
		'computerProgram' => ['software', 'high'],
		'journalArticle' => ['primary-paper', 'high'],
		'conferencePaper' => ['primary-paper', 'high'],
		'report' => ['primary-paper', 'medium'],
		'thesis' => ['primary-paper', 'medium'],
		'book' => ['book', 'high'],
		'bookSection' => ['book', 'medium'],
		'webpage' => ['web-page', 'high'],
		'blogPost' => ['web-page', 'high'],
		'dataset' => ['dataset', 'high'],
		'videoRecording' => ['video', 'high'],
		'encyclopediaArticle' => ['secondary-commentary', 'medium'],
		'newspaperArticle' => ['secondary-commentary', 'medium'],
		'document' => ['other', 'low']
	}.freeze

	REPO_HOSTS = %w[github.com gitlab.com bitbucket.org sourceforge.net].freeze

	module_function

	# Normalizes text: NFKD, strips combining marks (accents), downcases.
	#
	# @param s [String, nil]
	# @return [String]
	def norm_text(s)
		s.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '').downcase
	end

	# Tokenizes a title: strips reddit listing prefixes, splits on non-alnum,
	# drops stopwords, applies philosoph* aliases, strips naive plurals.
	#
	# @param title [String]
	# @return [Set<String>]
	def tokens(title)
		t = norm_text(title)
		t = t.sub(/\Ar\/\S+\s*[-–:]\s*/, '')
		t = t.gsub(/\[oc\]/, ' ')
		t.split(/[^a-z0-9]+/).each_with_object(Set.new) do |w, set|
			next if w.length < 2 || STOPWORDS.include?(w)
			w = ALIASES.fetch(w, w)
			w = w[0...-1] if w.length > 3 && w.end_with?('s') && w !~ /(ss|us|is|ous)$/
			set << w
		end
	end

	# @param url [String, nil]
	# @return [String] hostname without leading www., '' when absent/invalid
	def host_of(url)
		h = URI.parse(url.to_s).host.to_s.downcase
		h.start_with?('www.') ? h[4..] : h
	rescue URI::InvalidURIError
		''
	end

	# Project-identifying labels of a hostname (no TLDs or generic labels).
	#
	# @param host [String]
	# @return [Set<String>]
	def host_labels(host)
		host.split('.').reject { |l| l.empty? || TLD_LABELS.include?(l) || GENERIC_LABELS.include?(l) }.to_set
	end

	# First non-empty path segment of a URL, downcased ('' when none).
	#
	# @param url [String, nil]
	# @return [String]
	def first_path_segment(url)
		seg = URI.parse(url.to_s).path.to_s.split('/').reject(&:empty?).first.to_s.downcase
		seg
	rescue URI::InvalidURIError
		''
	end

	# @param item [Hash] Zotero item
	# @return [Integer, nil] first 4-digit year in the date field
	def year_of(item)
		m = item['data']['date'].to_s.match(/(19|20)\d{2}/)
		m && m[0].to_i
	end

	# Normalized creator surnames (single-field org names normalize whole).
	#
	# @param item [Hash] Zotero item
	# @return [Set<String>]
	def surnames_of(item)
		item['data'].fetch('creators', []).each_with_object(Set.new) do |c, set|
			nm = norm_text(c['lastName'] || c['name']).gsub(/[^a-z0-9]/, '')
			set << nm unless nm.empty?
		end
	end

	# Matchable creator full names: forename + surname as adjacent tokens.
	# Skips single-field (org/mononym) creators and forenames that are bare
	# initials — precision over recall (surname-only matching produced
	# forename/surname homonym false positives, e.g. Simon Raper's forename
	# tripping Herbert Simon's surname).
	#
	# @param item [Hash] Zotero item
	# @return [Set<Hash>] entries with 'phrase' (for text matching) and
	#   'label' (rendered as name:SURNAME_forename)
	def fullnames_of(item)
		item['data'].fetch('creators', []).each_with_object(Set.new) do |c, set|
			next if c['lastName'].nil?
			fore = norm_text(c['firstName']).split(/[^a-z0-9]+/).find { |t| t.length >= 2 }
			sur = norm_text(c['lastName']).split(/[^a-z0-9]+/).reject(&:empty?)
			next if fore.nil? || sur.empty?
			set << { 'phrase' => ([fore] + sur).join(' '), 'label' => "#{sur.join}_#{fore}" }
		end
	end

	# ==== Main pipeline ======================================================

	# Loads the snapshot, asserts population/orphan invariants, returns items.
	#
	# @return [Array(Hash, Hash)] snapshot wrapper, population items by key
	def load_population
		snap = JSON.parse(File.read(SNAPSHOT))
		ver = snap.dig('metadata', 'verification', 'child_parent_integrity', 'orphans')
		orphans = ver ? ver['standalone_count'] + ver['broken_ref_count'] : -1
		raise "snapshot reports #{orphans} orphans; Phase 1 expects 0 (Phase 0)" unless orphans.zero?
		pop = snap['items'].reject { |i| %w[attachment note].include?(i['data']['itemType']) }
		expected = snap.dig('metadata', 'counts', 'top_level')
		raise "population #{pop.size} != snapshot metadata top_level #{expected}" unless pop.size == expected
		by_key = {}
		pop.each { |i| raise "duplicate key #{i['key']}" if by_key.key?(i['key']); by_key[i['key']] = i }
		[snap, by_key]
	end

	# Builds all candidate edges over the population.
	#
	# @param by_key [Hash] key => Zotero item
	# @return [Hash] [a, b] (sorted) => {type => [[confidence, detail], ...]}
	def build_edges(by_key)
		keys = by_key.keys.sort
		ttok = keys.to_h { |k| [k, tokens(by_key[k]['data']['title'])] }
		hosts = keys.to_h { |k| [k, host_of(by_key[k]['data']['url'])] }
		labels = keys.to_h { |k| [k, host_labels(hosts[k])] }
		years = keys.to_h { |k| [k, year_of(by_key[k])] }
		surs = keys.to_h { |k| [k, surnames_of(by_key[k])] }
		dois = keys.to_h { |k| [k, by_key[k]['data']['DOI'].to_s.downcase] }
		abstxt = keys.to_h do |k|
			d = by_key[k]['data']
			[k, " #{norm_text("#{d['abstractNote']} #{d['extra']}").split(/[^a-z0-9]+/).reject(&:empty?).join(' ')} "]
		end
		cont = keys.to_h { |k| [k, tokens(by_key[k]['data']['bookTitle'] || by_key[k]['data']['proceedingsTitle'])] }

		df = Hash.new(0)
		ttok.each_value { |ts| ts.each { |t| df[t] += 1 } }
		ldf = Hash.new(0)
		labels.each_value { |ls| ls.each { |l| ldf[l] += 1 } }
		tagdf = Hash.new(0)
		by_key.each_value { |i| i['data'].fetch('tags', []).each { |t| tagdf[t['tag']] += 1 } }

		edges = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }
		add = lambda do |a, b, type, conf, detail|
			next if a == b
			a, b = [a, b].sort
			edges[[a, b]][type] << [conf, detail]
		end
		pairs = keys.combination(2)

		# title-overlap (+ distinctive-token lift, common-topic demotion)
		pairs.each do |a, b|
			shared = ttok[a] & ttok[b]
			next if shared.empty?
			j = shared.size.to_f / (ttok[a] | ttok[b]).size
			distinctive = shared.any? { |t| df[t] <= TITLE_DF_DISTINCTIVE }
			if shared.size >= 2 && j >= JACCARD_HIGH
				common_only = shared.all? { |t| df[t] > TITLE_DF_COMMON }
				det = { 'jaccard' => j.round(3), 'shared_tokens' => shared.sort }
				det['note'] = 'overlap on common-topic tokens only' if common_only
				add.call(a, b, 'title-overlap', common_only ? 'medium' : 'high', det)
			elsif shared.size >= 2 && j >= JACCARD_MEDIUM
				add.call(a, b, 'title-overlap', distinctive ? 'high' : 'medium',
					{ 'jaccard' => j.round(3), 'shared_tokens' => shared.sort })
			elsif shared.size == 1
				t = shared.first
				if df[t] <= TITLE_DF_DISTINCTIVE && t.length >= 6
					add.call(a, b, 'title-overlap', 'medium',
						{ 'jaccard' => j.round(3), 'shared_tokens' => [t], 'single_distinctive' => true })
				end
			end
		end

		# container: the user's structural bookTitle<->book convention (chapter
		# cliques + chapter->book). Structural context, NOT project-identity
		# evidence; excluded from clustering in finalize_edges.
		cgroups = Hash.new { |h, k| h[k] = [] }
		keys.each { |k| cgroups[cont[k].to_a.sort] << k unless cont[k].empty? }
		cgroups.each do |cs, ks|
			ks.sort!
			ks.combination(2) { |a, b| add.call(a, b, 'container', 'high', { 'container' => cs.join(' ')[0, 80] }) }
			cset = cs.to_set
			ks.each do |k|
				keys.each do |o|
					next if ks.include?(o) || by_key[o]['data']['itemType'] != 'book'
					tset = ttok[o]
					if cset.size >= 2 && cset.subset?(tset) && cset.size.to_f / tset.size >= 0.6
						add.call(k, o, 'container', 'high', { 'container' => 'contained-in-book' })
					end
				end
			end
		end

		# shared-identifier: same non-generic host (+ shared non-generic path segment)
		pairs.each do |a, b|
			ha, hb = hosts[a], hosts[b]
			next if ha.empty? || ha != hb || GENERIC_HOSTS.include?(ha)
			sa, sb = first_path_segment(by_key[a]['data']['url']), first_path_segment(by_key[b]['data']['url'])
			if !sa.empty? && sa == sb && !GENERIC_SEGMENTS.include?(sa)
				add.call(a, b, 'shared-identifier', 'high', { 'host' => ha, 'path' => sa })
			else
				add.call(a, b, 'shared-identifier', 'medium', { 'host' => ha })
			end
		end

		# shared-identifier: host-label evidence
		pairs.each do |a, b|
			[[a, b], [b, a]].each do |x, o|
				next if GENERIC_HOSTS.include?(hosts[o])
				ttok[x].each do |t|
					next if df[t] > 2
					if t.length >= 6 && labels[o].include?(t)
						add.call(a, b, 'shared-identifier', 'high', { 'title_token_is_host_label' => t })
					elsif t.length >= 3 && t =~ /\d/ && labels[o].any? { |l| l.length > t.length && l.start_with?(t) }
						add.call(a, b, 'shared-identifier', 'high', { 'title_token_host_label_prefix' => t })
					end
				end
			end
			next if hosts[a].empty? || hosts[b].empty? || hosts[a] == hosts[b] ||
				GENERIC_HOSTS.include?(hosts[a]) || GENERIC_HOSTS.include?(hosts[b])
			shared_labels = (labels[a] & labels[b]).select { |l| l.length >= 6 && ldf[l] <= 2 }
			if shared_labels.empty?
				[[a, b], [b, a]].each do |x, o|
					opath = norm_text(URI.parse(by_key[o]['data']['url'].to_s).path).split(/[^a-z0-9]+/).to_set
					labels[x].each do |l|
						if l.length >= 6 && ldf[l] <= 2 && opath.include?(l)
							add.call(a, b, 'shared-identifier', 'medium', { 'host_label_in_path' => l })
						end
					rescue URI::InvalidURIError
						next
					end
				end
			else
				add.call(a, b, 'shared-identifier', 'medium', { 'host_label' => shared_labels.sort })
			end
		end

		# shared-identifier: DOI identity, DOI-in-URL, shared DOI stem
		pairs.each do |a, b|
			da, db = dois[a], dois[b]
			next if da.empty? && db.empty?
			if !da.empty? && da == db
				add.call(a, b, 'shared-identifier', 'high', { 'doi' => da })
			elsif !da.empty? && by_key[b]['data']['url'].to_s.downcase.include?(da)
				add.call(a, b, 'shared-identifier', 'high', { 'doi_in_url' => da })
			elsif !db.empty? && by_key[a]['data']['url'].to_s.downcase.include?(db)
				add.call(a, b, 'shared-identifier', 'high', { 'doi_in_url' => db })
			end
		end
		stems = Hash.new { |h, k| h[k] = [] }
		dois.each do |k, d|
			next if d.empty?
			stems[d.sub(/\.ch-\d+$/, '').sub(/-\d+$/, '')] << k
		end
		stems.each_value do |ks|
			ks.sort.combination(2) { |a, b| add.call(a, b, 'shared-identifier', 'medium', { 'doi_stem' => true }) } if ks.size >= 2
		end

		# shared-tag (tags borne by 2..TAG_MAX_BEARERS items)
		surviving = tagdf.select { |_, n| n >= 2 && n <= TAG_MAX_BEARERS }.keys
		itags = keys.to_h { |k| [k, by_key[k]['data'].fetch('tags', []).map { |t| t['tag'] } & surviving] }
		pairs.each do |a, b|
			shared = itags[a] & itags[b]
			if shared.size >= 2
				add.call(a, b, 'shared-tag', 'high', { 'tags' => shared.sort })
			elsif shared.size == 1
				add.call(a, b, 'shared-tag', 'medium', { 'tags' => shared.sort })
			end
		end

		# shared-identifier: creator full name (forename + surname, adjacent
		# tokens) in another item's abstract/extra text; hitting <= 5 items
		fullnames = keys.to_h { |k| [k, fullnames_of(by_key[k])] }
		fn_ok = fullnames.values.reduce(&:union).to_a.select do |fn|
			keys.count { |b| abstxt[b].include?(" #{fn['phrase']} ") } <= 5
		end
		keys.each do |a|
			(fullnames[a] & fn_ok).each do |fn|
				keys.each do |b|
					add.call(a, b, 'shared-identifier', 'medium', { 'name_in_text' => fn['label'] }) if a != b && abstxt[b].include?(" #{fn['phrase']} ")
				end
			end
		end

		# creator-year (weak by spec: always low confidence)
		pairs.each do |a, b|
			shared = surs[a] & surs[b]
			next if shared.empty? || years[a].nil? || years[b].nil? || (years[a] - years[b]).abs > CREATOR_YEAR_WINDOW
			add.call(a, b, 'creator-year', 'low', { 'surnames' => shared.sort, 'years' => [years[a], years[b]] })
		end

		# related-link: dc:relation URIs resolving inside the population
		keys.each do |a|
			dr = by_key[a]['data'].fetch('relations', {})['dc:relation']
			next if dr.nil?
			(dr.is_a?(Array) ? dr : [dr]).each do |v|
				m = v.to_s.match(%r{/users/\d+/items/([A-Z0-9]+)})
				add.call(a, m[1], 'related-link', 'high', { 'uri' => v.to_s }) if m && by_key.key?(m[1])
			end
		end

		edges
	end

	# Computes final per-pair confidence with promotion rules.
	#
	# @param edges [Hash] from build_edges
	# @return [Hash] [a, b] => {types:, confidence:, detail:}
	def finalize_edges(edges)
		structural = ->(type) { %w[creator-year container].include?(type) }
		edges.each_with_object({}) do |((a, b), tmap), out|
			per_type = tmap.transform_values { |ds| ds.map(&:first).max_by { |c| CONFIDENCE[c] } }
			clusterable = per_type.reject { |type, _| structural.call(type) }
			conf = clusterable.empty? ? 0 : CONFIDENCE[clusterable.values.max_by { |c| CONFIDENCE[c] }]
			eligible = tmap.any? do |type, ds|
				next false if structural.call(type)
				ds.any? { |c, d| c != 'low' && !d['doi_stem'] && !d['single_distinctive'] && !d['note'] }
			end
			conf = 2 if conf < 2 && tmap.count { |type, ds|
				next false if structural.call(type)
				ds.any? { |c, d| c != 'low' && !d['doi_stem'] && !d['single_distinctive'] && !d['note'] }
			} >= 2
			conf = 2 if conf < 2 && per_type['title-overlap'] == 'medium' && tmap.key?('creator-year')
			detail = tmap.transform_values { |ds| ds.map { |c, d| d.merge('confidence' => c) } }
			out[[a, b]] = { 'types' => tmap.keys.sort, 'confidence' => %w[low medium high][conf], 'detail' => detail }
		end
	end

	# Loads the decisions ledger (append-only JSONL, last-wins per key;
	# gate records are keyed per (pair, channel)). Tolerates absence: an
	# empty ledger means generator defaults throughout. Gate records without
	# a +channel+ field are backfill-normalized by value (part-of is
	# containment, everything else membership).
	#
	# @return [Hash] {'gates' => [[a, b] (sorted), channel] => gate,
	#   'assignments' => key => value, 'anchors' => key => name,
	#   'notes' => key => text, 'inventory' => artifact ID => record}
	def load_decisions
		d = { 'gates' => {}, 'assignments' => {}, 'anchors' => {}, 'notes' => {}, 'inventory' => {} }
		return d unless File.exist?(DECISIONS)
		File.readlines(DECISIONS).each_with_index do |line, n|
			line = line.strip
			next if line.empty?
			begin
				rec = JSON.parse(line)
			rescue JSON::ParserError => e
				raise "decisions ledger line #{n + 1} is not valid JSON: #{e.message}"
			end
			case rec['type']
			when 'gate'
				a, b = [rec['a'], rec['b']].sort
				raise "decisions ledger line #{n + 1}: gate record needs a, b, gate" if a.nil? || b.nil? || rec['gate'].nil?
				channel = rec['channel'] || (rec['gate'] == 'part-of' ? 'containment' : 'membership')
				unless %w[membership containment].include?(channel)
					raise "decisions ledger line #{n + 1}: unknown channel #{channel.inspect}"
				end
				d['gates'][[[a, b], channel]] = rec['gate']
			when 'assignment'
				d['assignments'][rec['key']] = rec['value']
			when 'project'
				# name null retires an anchor (cluster dissolved at the gate)
				rec['name'].nil? ? d['anchors'].delete(rec['key']) : d['anchors'][rec['key']] = rec['name']
			when 'note'
				d['notes'][rec['key']] = rec['text']
			when 'inventory'
				unless rec['id'].is_a?(String) && rec['id'].match?(/\AEP-\d{3,}\/.+\z/) && %w[required optional not-expected].include?(rec['requirement'])
					raise "decisions ledger line #{n + 1}: invalid inventory ruling"
				end
				d['inventory'][rec['id']] = rec
			else
				raise "decisions ledger line #{n + 1}: unknown type #{rec['type'].inspect}"
			end
		end
		d
	end

	# Decision overlay on the finalized edges (run after finalize_edges),
	# applied per channel: the MEMBERSHIP ruling is stored as e['decision'],
	# the CONTAINMENT ruling as e['containment']; sheet rows show
	# gate: e['decision'] and containment: e['containment'] || pre_gate(e).
	# Pairs with no evidence edge get a synthesized 'decision' edge
	# (membership rulings: confidence high; containment rulings: confidence
	# low so the evidence rule never welds on them) Rows derive from
	# the single edge map, so mirror copies inherit the rulings
	# automatically.
	#
	# @param final [Hash] from finalize_edges (mutated)
	# @param decisions [Hash] from load_decisions
	# @param by_key [Hash] key => Zotero item
	# @return [void]
	def apply_decisions(final, decisions, by_key)
		decisions['gates'].each do |((a, b), channel), gate|
			unless by_key.key?(a) && by_key.key?(b)
				warn "decisions ledger: #{channel} gate #{a} <-> #{b} references item outside population — skipped"
				next
			end
			e = final[[a, b]]
			if e.nil?
				if channel == 'membership'
					e = final[[a, b]] = { 'types' => ['decision'], 'confidence' => 'high',
						'detail' => { 'decision' => [{ 'confidence' => 'high', 'ledger' => true }] } }
				else
					# containment rulings get a LOW-confidence synthesized edge so
					# the evidence rule (high welds) never welds on them
					e = final[[a, b]] = { 'types' => ['decision'], 'confidence' => 'low',
						'detail' => { 'decision' => [{ 'confidence' => 'low', 'ledger' => true, 'containment_only' => true }] } }
				end
			end
			channel == 'membership' ? e['decision'] = gate : e['containment'] = gate
		end
	end

	# Decision-resolved weld rule (membership channel only): a membership
	# +same-project+ ruling always welds; any other membership ruling cuts
	# (even when evidence is high); undecided edges weld on HIGH confidence
	# (container/creator-year never reach high by construction in
	# finalize_edges). Containment rulings NEVER weld and never cut.
	#
	# @param e [Hash] finalized edge (with optional 'decision'/'containment')
	# @return [Boolean]
	def welds?(e)
		return e['decision'] == 'same-project' if e['decision']
		e['confidence'] == 'high'
	end

	# Connected components over welding edges (union-find).
	#
	# @param keys [Array<String>]
	# @param final [Hash] from finalize_edges (+ decision overlay)
	# @return [Array<Array<String>>] clusters (size >= 2), sorted members
	def cluster(keys, final)
		parent = keys.to_h { |k| [k, k] }
		find = lambda do |x|
			root = x
			root = parent[root] while parent[root] != root
			while parent[x] != root
				parent[x], x = root, parent[x]
			end
			root
		end
		final.each do |(a, b), e|
			next unless welds?(e)
			ra, rb = find.call(a), find.call(b)
			parent[rb] = ra unless ra == rb
		end
		comp = Hash.new { |h, k| h[k] = [] }
		keys.each { |k| comp[find.call(k)] << k }
		comp.values.select { |v| v.size > 1 }.map(&:sort)
	end

	# Role proposal per §2.1 from itemType (+URL patterns).
	#
	# @param item [Hash]
	# @return [Array(String, String)] role, confidence
	def role_of(item)
		ROLE_MAP.fetch(item['data']['itemType'], ['other', 'low'])
	end

	# Non-project proposal: reference/news/generic media items on platform
	# hosts with no high-confidence edges.
	#
	# @param item [Hash]
	# @param host [String]
	# @param has_high [Boolean]
	# @return [String, nil] reason, or nil
	def non_project_reason(item, host, has_high)
		return nil if has_high
		type = item['data']['itemType']
		if %w[encyclopediaArticle newspaperArticle].include?(type) && (host.empty? || GENERIC_HOSTS.include?(host))
			'reference/news item on a platform host, no artefact links — confirm non-project'
		elsif type == 'videoRecording' && GENERIC_HOSTS.include?(host)
			'generic media item on a platform host, no artefact links — confirm non-project'
		end
	end

	# NEEDS-YOU flags for a cluster (list of strings, deterministic).
	def cluster_flags(members, internal, by_key, outgoing = {})
		flags = []
		flags << "large component (#{members.size} items) — likely several projects; confirm splits" if members.size >= LARGE_CLUSTER
		internal.each do |(a, b), e|
			next unless e['confidence'] == 'high'
			e['detail'].fetch('title-overlap', []).each do |d|
				shared_surs = surnames_of(by_key[a]) & surnames_of(by_key[b])
				if d['jaccard'].to_f >= 0.8 && !shared_surs.empty?
					flags << "probable duplicate/version records: #{a} <-> #{b} (j=#{d['jaccard']}, shared creators) — consider merge"
				end
			end
		end
		if internal.merge(outgoing).any? { |(_, _), e| e['detail'].key?('container') }
			flags << 'contains same-volume (container) links — confirm whether the volume is the project or context'
		end
		hosts = members.map { |k| host_of(by_key[k]['data']['url']) }
		if hosts.any? { |h| GENERIC_HOSTS.include?(h) } && hosts.any? { |h| !h.empty? && !GENERIC_HOSTS.include?(h) }
			flags << 'commentary + artefact mix (generic and project hosts) — type edges at gate'
		elsif hosts.none? { |h| h.empty? || !GENERIC_HOSTS.include?(h) }
			flags << 'commentary-only cluster (all members on platform hosts) — subject artefact may be absent from the collection'
		end
		flags.uniq.sort
	end

	# Expected-artifact inventory proposal for an audit unit (§2.2).
	#
	# @param members [Array<String>]
	# @param by_key [Hash]
	# @param pid [String] EP audit-unit ID (EP-###)
	# @return [Array<Hash>] inventory entries, all proposed
	def inventory_for(members, by_key, pid)
		inv = []
		papers = members.select { |k| role_of(by_key[k]).first == 'primary-paper' }
		books = members.select { |k| role_of(by_key[k]).first == 'book' }
		soft = members.select { |k| role_of(by_key[k]).first == 'software' }
		web = members.select { |k| role_of(by_key[k]).first == 'web-page' }
		data = members.select { |k| role_of(by_key[k]).first == 'dataset' }
		vid = members.select { |k| role_of(by_key[k]).first == 'video' }
		comm = members.select { |k| role_of(by_key[k]).first == 'secondary-commentary' }
		other = members.select { |k| role_of(by_key[k]).first == 'other' }
		papers.sort.each_with_index do |k, i|
			name = i.zero? ? 'paper/main' : "paper/followup-#{i}"
			inv << { 'id' => "#{pid}/#{name}", 'requirement' => i.zero? ? 'required' : 'optional', 'proposed' => true, 'basis' => "#{by_key[k]['data']['itemType']} #{k}" }
		end
		books.sort.each_with_index do |k, i|
			name = i.zero? ? 'book/main' : "book/other-#{i}"
			inv << { 'id' => "#{pid}/#{name}", 'requirement' => i.zero? ? 'required' : 'optional', 'proposed' => true, 'basis' => "#{by_key[k]['data']['itemType']} #{k}" }
		end
		soft.sort.each_with_index do |k, i|
			repo = REPO_HOSTS.include?(host_of(by_key[k]['data']['url']))
			name = i.zero? ? (repo ? 'software/repo' : 'software/site') : "software/other-#{i}"
			inv << { 'id' => "#{pid}/#{name}", 'requirement' => i.zero? ? 'required' : 'optional', 'proposed' => true, 'basis' => "computerProgram #{k}" }
		end
		web.sort.each_with_index do |k, i|
			inv << { 'id' => "#{pid}/web/site#{i.zero? ? '' : "-#{i}"}", 'requirement' => 'optional', 'proposed' => true, 'basis' => "#{by_key[k]['data']['itemType']} #{k}" }
		end
		data.sort.each_with_index do |k, i|
			inv << { 'id' => "#{pid}/dataset/#{i.zero? ? 'main' : "other-#{i}"}", 'requirement' => i.zero? ? 'required' : 'optional', 'proposed' => true, 'basis' => "dataset #{k}" }
		end
		vid.sort.each_with_index do |k, i|
			inv << { 'id' => "#{pid}/video/#{i.zero? ? 'main' : "other-#{i}"}", 'requirement' => 'optional', 'proposed' => true, 'basis' => "videoRecording #{k}" }
		end
		comm.sort.each_with_index do |k, i|
			inv << { 'id' => "#{pid}/commentary/#{i.zero? ? 'main' : "other-#{i}"}", 'requirement' => 'optional', 'proposed' => true, 'basis' => "#{by_key[k]['data']['itemType']} #{k}" }
		end
		other.sort.each { |k| inv << { 'id' => "#{pid}/misc/#{k}", 'requirement' => 'unknown', 'proposed' => true, 'basis' => "#{by_key[k]['data']['itemType']} #{k}" } }
		inv << { 'id' => "#{pid}/paper/main", 'requirement' => 'unknown', 'proposed' => true, 'basis' => 'no paper-role member' } if papers.empty? && books.empty?
		inv << { 'id' => "#{pid}/software/repo", 'requirement' => 'unknown', 'proposed' => true, 'basis' => 'no software member' } if soft.empty?
		inv
	end

	# Applies last-wins human inventory rulings to machine proposals.
	# Confirmed entries retain their proposal basis; not-expected removes the row.
	# New artifacts require an explicit basis and are added with proposed false.
	#
	# @param inventory [Array<Hash>] machine-proposed entries
	# @param rulings [Hash] artifact ID => ledger record
	# @param unit_id [String] owning audit-unit EP ID
	# @return [Array<Hash>] derived inventory
	def apply_inventory_decisions(inventory, rulings, unit_id)
		derived = inventory.each_with_object([]) do |entry, result|
			ruling = rulings[entry['id']]
			if ruling.nil?
				result << entry
			elsif ruling['requirement'] != 'not-expected'
				confirmed = entry.merge('requirement' => ruling['requirement'], 'proposed' => false)
				%w[date note evidence].each { |field| confirmed[field] = ruling[field] if ruling.key?(field) }
				result << confirmed
			end
		end
		rulings.each do |artifact_id, ruling|
			next unless artifact_id.start_with?("#{unit_id}/") && derived.none? { |entry| entry['id'] == artifact_id }
			next if ruling['requirement'] == 'not-expected'
			raise "new inventory artifact #{artifact_id} needs a basis" if ruling['basis'].to_s.empty?
			entry = { 'id' => artifact_id, 'requirement' => ruling['requirement'], 'proposed' => false, 'basis' => ruling['basis'] }
			%w[date note evidence].each { |field| entry[field] = ruling[field] if ruling.key?(field) }
			derived << entry
		end
		derived
	end

	# Short edge summary for display.
	def edge_summary(e)
		e['detail'].map do |type, ds|
			ds.map do |d|
				bits = [type]
				bits << "j=#{d['jaccard']}" if d['jaccard']
				bits << (d['shared_tokens'] ? "{#{d['shared_tokens'].join(', ')}}" : '') if d['shared_tokens']
				bits << d['host'].to_s if d['host']
				bits << d['container'].to_s[0, 40] if d['container']
				bits << d['tags'].join(', ') if d['tags']
				bits << "name:#{d['name_in_text']}" if d['name_in_text']
				bits << d['surnames'].join(', ') if d['surnames']
				bits << 'doi-stem' if d['doi_stem']
				bits << 'ledger' if d['ledger']
				bits.reject(&:empty?).join(' ') + " (#{d['confidence']})"
			end
		end.flatten.uniq.join(' + ')
	end

	# Pre-typed containment for edges verified by the user's container
	# convention. Feeds the row's +containment:+ field when no ledger
	# containment ruling exists; never feeds +gate:+ (membership).
	# @param e [Hash] finalized edge
	# @return [String, nil] 'part-of' for contained-in-book, else nil
	def pre_gate(e)
		'part-of' if e['detail'].fetch('container', []).any? { |d| d['container'] == 'contained-in-book' }
	end

	# Ruling fields for an edge/link sheet row (two-channel model):
	# +gate:+ is the MEMBERSHIP ruling (nil when undecided);
	# +containment:+ is the ledger containment ruling, else the +pre_gate+
	# part-of default — the key is included only when a value exists.
	#
	# @param e [Hash] finalized edge (with optional 'decision'/'containment')
	# @return [Hash] {'gate' => String, nil} plus optional 'containment'
	def ruling_fields(e)
		row = { 'gate' => e['decision'] }
		containment = e['containment'] || pre_gate(e)
		row['containment'] = containment if containment
		row
	end

	# Runs the pipeline, writes both sheets, prints the report.
	#
	# @return [void]
	def run
		snap, by_key = load_population
		keys = by_key.keys.sort
		years = keys.to_h { |k| [k, year_of(by_key[k])] }
		decisions = load_decisions

		edges = build_edges(by_key)
		final = finalize_edges(edges)
		apply_decisions(final, decisions, by_key)
		clusters = cluster(keys, final)
		clustered = clusters.flatten.to_set

		# assignment records force items into/out of the non_project section
		forced_non_project = decisions['assignments'].select { |k, v| v == 'non-project' && by_key.key?(k) }
		forced_unresolved = decisions['assignments'].select { |k, v| v == 'unresolved' && by_key.key?(k) }
		(decisions['assignments'].keys - by_key.keys).each do |k|
			warn "decisions ledger: assignment for #{k} outside population — skipped"
		end
		(forced_non_project.keys & clustered.to_a).each do |k|
			warn "decisions ledger: #{k} is assigned non-project but welds into a cluster — cluster wins"
		end

		# Legacy project records anchor audit units: an unclustered anchor key
		# retains an EP ID as a singleton (for example, a program whose papers
		# were all split to describes-singletons).
		anchor_names = {}
		decisions['anchors'].each do |k, name|
			next if clustered.include?(k) || forced_non_project.key?(k)
			unless by_key.key?(k)
				warn "decisions ledger: audit-unit anchor #{k} outside population — skipped"
				next
			end
			clusters << [k]
			clustered << k
			anchor_names[k] = name
		end

		# non-project proposals out of the unclustered remainder
		high_keys = final.select { |_, e| e['confidence'] == 'high' }.flat_map { |(a, b), _| [a, b] }.to_set
		non_project = {}
		(keys - clustered.to_a).each do |k|
			next if forced_unresolved.key?(k)
			reason = non_project_reason(by_key[k], host_of(by_key[k]['data']['url']), high_keys.include?(k))
			non_project[k] = reason if reason
		end
		(forced_non_project.keys - clustered.to_a).each do |k|
			non_project[k] ||= 'confirmed non-project (decisions ledger)'
		end
		singletons = keys - clustered.to_a - non_project.keys

		# order clusters by earliest year, then proposed name; assign EP ids
		decorated = clusters.map do |members|
			software = members.select { |k| role_of(by_key[k]).first == 'software' }
			name_source = (software.first || members.min_by { |k| [years[k] || 9999, k] })
			name = by_key[name_source]['data']['title'].to_s.sub(/\Ar\/\S+\s*[-–:]\s*/, '').strip
			name = anchor_names[members.first] if members.size == 1 && anchor_names.key?(members.first)
			{ 'members' => members, 'name' => name, 'year' => members.map { |k| years[k] }.compact.min }
		end
		decorated.sort_by! { |c| [c['year'] || 9999, c['name'].downcase] }
		singleton_records = ZoteroSingletonIds.load(SINGLETON_IDS)
		singleton_ids = singleton_records.each_with_object({}) { |record, by_key| by_key[record['key']] = record['id'] }
		identity = File.exist?(IDENTITY_SHEET) ? YAML.load_file(IDENTITY_SHEET) : nil
		identity_units = {}
		(identity ? identity.fetch('proposed_clusters', []) : []).each do |unit|
			identity_units[unit['members'].map { |member| member['key'] }.sort] = unit['id']
		end
		previous_id_map = File.exist?(IDMAP) ? JSON.parse(File.read(IDMAP)) : {}
		previous_mappings = previous_id_map.fetch('old_to_new', {})
		reserved_ep_ids = singleton_ids.values + previous_mappings.keys + previous_mappings.values +
			previous_id_map.fetch('retired', []) + previous_id_map.fetch('new', []) +
			(identity ? identity.fetch('id_log', []).map { |entry| entry['id'] } : []) + identity_units.values
		next_ep_number = reserved_ep_ids.map { |id| id[/\AEP-(\d{3,})\z/, 1] }.compact.map(&:to_i).max.to_i + 1
		decorated.each do |unit|
			preserved = unit['members'].size == 1 ? singleton_ids[unit['members'].first] : identity_units[unit['members'].sort]
			preserved ||= identity_units[unit['members'].sort]
			unit['id'] = preserved || format('EP-%03d', next_ep_number)
			next_ep_number += 1 unless preserved
		end
		pid_of = {}
		decorated.each { |c| c['members'].each { |k| pid_of[k] = c['id'] } }

		# ID remap: match the previous sheet's effective cluster member-sets
		# (honouring human assignment edits) against the new clusters — most
		# shared member keys wins; unmatched old IDs are retired. The identity
		# sheet's id_log takes precedence so retirement dates/reasons remain stable.
		id_log = identity ? (identity['id_log'] || []) : []
		id_map_output = nil
		if File.exist?(PREV_SHEET) && File.expand_path(PREV_SHEET) != File.expand_path(OUT_YAML)
			old = YAML.load_file(PREV_SHEET)
			id_log = old['id_log'] || [] if id_log.empty?
			old_clusters = {}
			(old['proposed_clusters'] || []).each do |c|
				old_clusters[c['id']] = c['members'].select { |m| m['assignment'] == c['id'] }.map { |m| m['key'] }
			end
			(old['singletons'] || []).each do |s|
				old_clusters[s['assignment']] |= [s['key']] if old_clusters.key?(s['assignment'])
			end
			old_to_new = {}
			retired = []
			old_clusters.sort.each do |oid, members|
				best = decorated.max_by { |c| (c['members'] & members).size }
				if members.empty? || best.nil? || (best['members'] & members).empty?
					retired << oid
				else
					old_to_new[oid] = best['id']
				end
			end
			new_ids = decorated.map { |c| c['id'] } - old_to_new.values
			logged = id_log.map { |l| l['id'] }
			(retired - logged).each do |oid|
				id_log << { 'id' => oid, 'date' => Date.today.iso8601,
					'reason' => "retired by #{SHEET_NAME} regen — no cluster in the regenerated sheet shares its members" }
			end
			id_map_output = { 'old_to_new' => old_to_new, 'retired' => retired, 'new' => new_ids }
			puts "id remap: #{old_to_new.size} mapped; retired #{retired.size} (#{retired.join(', ')}); new #{new_ids.size} (#{new_ids.join(', ')})"
		end

		ordered_singletons = singletons.sort_by { |k| [years[k] || 9999, by_key[k]['data']['title'].to_s.downcase, k] }
		reserved_ep_ids.concat(decorated.map { |unit| unit['id'] } + id_log.map { |entry| entry['id'] })
		preserved_singleton_ids = decorated.select { |unit| unit['members'].size == 1 }.map { |unit| singleton_ids[unit['members'].first] }.compact
		collision_reserved_ids = reserved_ep_ids.compact.uniq - singleton_ids.values
		singleton_ids = ZoteroSingletonIds.reconcile(SINGLETON_IDS, ordered_singletons, collision_reserved_ids,
			allowed_ids: preserved_singleton_ids, persist: false)
		singletons.each { |k| pid_of[k] = singleton_ids.fetch(k) }

		# Content for anchored complexes and singletons.
		proposed_artifact_ids = []
		projects = decorated.map do |c|
			members = c['members']
			internal = final.select { |(a, b), _| members.include?(a) && members.include?(b) }
			outgoing = final.select do |(a, b), e|
				(members.include?(a) != members.include?(b)) && !welds?(e)
			end
			edge_rows = internal.sort_by { |(a, b), _| [a, b] }.map do |(a, b), e|
				{ 'a' => a, 'b' => b, 'types' => e['types'], 'confidence' => e['confidence'],
					'detail' => edge_summary(e) }.merge(ruling_fields(e))
			end
			link_rows = outgoing.sort_by { |(a, b), _| [a, b] }.map do |(a, b), e|
				other = members.include?(a) ? b : a
				row = { 'member' => members.include?(a) ? a : b, 'other_key' => other,
					'other_title' => by_key[other]['data']['title'].to_s[0, 80], 'types' => e['types'],
					'confidence' => e['confidence'], 'detail' => edge_summary(e) }.merge(ruling_fields(e))
				row['to_project'] = pid_of[other] if pid_of[other]
				row
			end
			flags = cluster_flags(members, internal, by_key, outgoing)
			inv = inventory_for(members, by_key, c['id'])
			proposed_artifact_ids.concat(inv.map { |entry| entry['id'] })
			inv = apply_inventory_decisions(inv, decisions['inventory'], c['id'])
			flags << 'inventory contains unknowns — set at gate' if inv.any? { |x| x['requirement'] == 'unknown' }
			{
				'id' => c['id'], 'grouping' => members.size > 1 ? 'complex' : 'singleton',
				'proposed_name' => c['name'], 'display_only' => true,
				'earliest_year' => c['year'], 'needs_you' => flags,
				'members' => members.sort_by { |k| [years[k] || 9999, k] }.map do |k|
					role, rconf = role_of(by_key[k])
					row = { 'key' => k, 'assignment' => c['id'], 'year' => years[k], 'role' => role,
						'role_confidence' => rconf, 'title' => by_key[k]['data']['title'].to_s,
						'url_host' => host_of(by_key[k]['data']['url']) }
					row['note'] = decisions['notes'][k] if decisions['notes'].key?(k)
					row
				end,
				'edges' => edge_rows,
				'candidate_links' => link_rows,
				'inventory' => inv
			}
		end

		singleton_rows = ordered_singletons.map do |k|
			role, rconf = role_of(by_key[k])
			links = final.select { |(a, b), _| a == k || b == k }.sort_by { |(a, b), _| [a, b] }.map do |(a, b), e|
				other = a == k ? b : a
				row = { 'to' => other, 'to_title' => by_key[other]['data']['title'].to_s[0, 80],
					'types' => e['types'], 'confidence' => e['confidence'], 'detail' => edge_summary(e) }.merge(ruling_fields(e))
				row['to_project'] = pid_of[other] if pid_of[other]
				row
			end
			inv = inventory_for([k], by_key, singleton_ids.fetch(k))
			proposed_artifact_ids.concat(inv.map { |entry| entry['id'] })
			inv = apply_inventory_decisions(inv, decisions['inventory'], singleton_ids.fetch(k))
			flags = inv.any? { |entry| entry['requirement'] == 'unknown' } ? ['inventory contains unknowns — set at gate'] : []
			row = { 'id' => singleton_ids.fetch(k), 'grouping' => 'singleton',
				'key' => k, 'assignment' => 'unresolved', 'status' => 'unpaired — confirm',
				'needs_you' => flags, 'year' => years[k], 'role' => role, 'role_confidence' => rconf,
				'title' => by_key[k]['data']['title'].to_s, 'url_host' => host_of(by_key[k]['data']['url']),
				'candidate_links' => links, 'inventory' => inv }
			row['note'] = decisions['notes'][k] if decisions['notes'].key?(k)
			row
		end

		non_project_rows = non_project.keys.sort_by { |k| [years[k] || 9999, k] }.map do |k|
			role, rconf = role_of(by_key[k])
			row = { 'key' => k, 'assignment' => 'non-project', 'needs_you' => !forced_non_project.key?(k),
				'reason' => non_project[k],
				'year' => years[k], 'role' => role, 'role_confidence' => rconf,
				'title' => by_key[k]['data']['title'].to_s, 'url_host' => host_of(by_key[k]['data']['url']) }
			row['note'] = decisions['notes'][k] if decisions['notes'].key?(k)
			row
		end

		calibration = CALIBRATION.map do |label, a, b|
			e = final[[a, b].sort]
			{ 'pair' => label, 'a' => a, 'b' => b, 'surfaced' => !e.nil?,
				'confidence' => e && e['confidence'], 'types' => e && e['types'],
				'same_cluster' => !!(pid_of[a] && pid_of[a] == pid_of[b]) }
		end

		tagdf = Hash.new(0)
		by_key.each_value { |i| i['data'].fetch('tags', []).each { |t| tagdf[t['tag']] += 1 } }
		suppressed = tagdf.select { |_, n| n > TAG_MAX_BEARERS }.sort.map { |t, n| { 'tag' => t, 'bearers' => n } }

		type_counts = Hash.new(0)
		conf_counts = Hash.new(0)
		final.each_value do |e|
			e['types'].each { |t| type_counts[t] += 1 }
			conf_counts[e['confidence']] += 1
		end

		complex_count = projects.count { |unit| unit['grouping'] == 'complex' }
		anchored_singleton_count = projects.count { |unit| unit['grouping'] == 'singleton' }
		sheet = {
			'sheet' => SHEET_NAME,
			'generated_from' => {
				'snapshot' => File.basename(SNAPSHOT),
				'snapshot_sha256' => Digest::SHA256.file(SNAPSHOT).hexdigest,
				'library_version' => snap.dig('metadata', 'last_modified_version'),
				'generator' => 'scripts/zotero_cluster.rb',
				'decisions' => File.exist?(DECISIONS) ? File.basename(DECISIONS) : nil,
				'singleton_ids' => File.basename(SINGLETON_IDS),
				'population' => keys.size,
				'orphan_register' => '0 orphans (Phase 0)'
			},
			'instructions' => INSTRUCTIONS,
			'parameters' => {
				'clustering' => 'connected components over decision-resolved welding edges (membership same-project always welds, any other membership ruling cuts, else high-confidence welds; containment and container/creator-year never weld)',
				'jaccard_high' => JACCARD_HIGH, 'jaccard_medium' => JACCARD_MEDIUM,
				'title_df_distinctive' => TITLE_DF_DISTINCTIVE, 'title_df_common' => TITLE_DF_COMMON,
				'tag_max_bearers' => TAG_MAX_BEARERS, 'creator_year_window' => CREATOR_YEAR_WINDOW,
				'promotion' => 'high when >= 2 promotion-eligible medium+ evidence types, or medium title-overlap + creator-year',
				'not_promotion_eligible' => 'doi-stem, single-distinctive-token, common-topic-only mediums',
				'generic_hosts' => GENERIC_HOSTS
			},
			'statistics' => {
				'population' => keys.size, 'proposed_clusters' => projects.size, 'clustered_items' => clustered.size,
				'complexes' => complex_count, 'complex_items' => projects.select { |unit| unit['grouping'] == 'complex' }.sum { |unit| unit['members'].size },
				'anchored_singletons' => anchored_singleton_count, 'unanchored_singletons' => singleton_rows.size,
				'singletons' => anchored_singleton_count + singleton_rows.size,
				'audit_units' => projects.size + singleton_rows.size, 'non_project' => non_project_rows.size,
				'edges_total' => final.size, 'edges_by_confidence' => conf_counts.sort.to_h,
				'edges_by_type' => type_counts.sort.to_h
			},
			'calibration' => calibration,
			'suppressed_tags' => suppressed,
			'id_log' => id_log,
			'proposed_clusters' => projects,
			'singletons' => singleton_rows,
			'non_project' => non_project_rows
		}

		# ==== verification ====
		assigned = projects.flat_map { |p| p['members'].map { |m| m['key'] } } +
			singleton_rows.map { |r| r['key'] } + non_project_rows.map { |r| r['key'] }
		raise "accounting invariant violated: #{assigned.size} assignments, #{assigned.uniq.size} unique, population #{keys.size}" unless assigned.sort == keys
		final.each_key { |(a, b)| raise "edge target #{a}/#{b} outside population" unless by_key.key?(a) && by_key.key?(b) }
		audit_units = projects + singleton_rows
		key_to_id = {}
		projects.each { |unit| unit['members'].each { |member| key_to_id[member['key']] = unit['id'] } }
		singleton_rows.each { |row| key_to_id[row['key']] = row['id'] }
		projects.each do |unit|
			unit['candidate_links'].each do |link|
				expected = key_to_id[link['other_key']]
				raise "incorrect cross-ref target for #{link['other_key']}: #{link['to_project'].inspect}, expected #{expected.inspect}" unless link['to_project'] == expected
			end
		end
		singleton_rows.each do |row|
			row['candidate_links'].each do |link|
				expected = key_to_id[link['to']]
				raise "incorrect cross-ref target for #{link['to']}: #{link['to_project'].inspect}, expected #{expected.inspect}" unless link['to_project'] == expected
			end
		end
		calibration.each { |c| raise "calibration pair missing: #{c['pair']}" unless c['surfaced'] }
		unit_ids = audit_units.map { |unit| unit['id'] }
		raise "duplicate audit-unit EP IDs: #{ZoteroSingletonIds.duplicates(unit_ids).join(', ')}" unless unit_ids.uniq.size == unit_ids.size
		raise "missing inventory for an audit unit" if audit_units.any? { |unit| !unit['inventory'].is_a?(Array) }
		audit_units.each do |unit|
			unit['inventory'].each do |entry|
				valid = entry['id'].is_a?(String) && entry['id'].match?(/\AEP-\d{3,}\/.+\z/) &&
					%w[required optional unknown].include?(entry['requirement']) && [true, false].include?(entry['proposed']) && entry['basis'].is_a?(String)
				raise "invalid inventory entry in #{unit['id']}: #{entry.inspect}" unless valid
			end
		end
		artifact_ids = audit_units.flat_map { |unit| unit['inventory'].map { |entry| entry['id'] } }
		raise "duplicate artifact IDs: #{ZoteroSingletonIds.duplicates(artifact_ids).join(', ')}" unless artifact_ids.uniq.size == artifact_ids.size
		missing_inventory_rulings = decisions['inventory'].keys - proposed_artifact_ids
		invalid_additions = missing_inventory_rulings.select { |id| decisions['inventory'][id]['requirement'] == 'not-expected' || decisions['inventory'][id]['basis'].to_s.empty? }
		raise "new inventory rulings need an expected artifact and basis: #{invalid_additions.join(', ')}" unless invalid_additions.empty?
		singleton_rows.each do |row|
			expected = row['inventory'].any? { |entry| entry['requirement'] == 'unknown' } ? ['inventory contains unknowns — set at gate'] : []
			raise "incorrect singleton NEEDS-YOU flags for #{row['key']}" unless row['needs_you'] == expected
		end
		raise "singleton ID allocation is incomplete" unless ordered_singletons.all? { |key| singleton_ids[key].is_a?(String) }

		yaml_output = sheet.to_yaml
		markdown_output = render_markdown(sheet, final, by_key)
		File.write(IDMAP, JSON.pretty_generate(id_map_output) + "\n") if id_map_output
		ZoteroSingletonIds.write(SINGLETON_IDS, singleton_ids.map { |key, id| { 'key' => key, 'id' => id } })
		File.write(OUT_YAML, yaml_output)
		File.write(OUT_MD, markdown_output)

		histogram = projects.select { |unit| unit['grouping'] == 'complex' }.map { |unit| unit['members'].size }.each_with_object(Hash.new(0)) { |n, h| h[n] += 1 }.sort.to_h
		puts "decisions: #{decisions['gates'].size} gates, #{decisions['assignments'].size} assignments, #{decisions['anchors'].size} audit-unit anchors, #{decisions['notes'].size} notes#{File.exist?(DECISIONS) ? '' : ' (no ledger)'}"
		puts "complexes: #{complex_count} (size histogram: #{histogram})"
		puts "singletons: #{anchored_singleton_count + singleton_rows.size} (#{anchored_singleton_count} anchored + #{singleton_rows.size} unanchored); non-project: #{non_project_rows.size}"
		puts "audit units with inventories: #{audit_units.size}"
		puts "NEEDS-YOU: audit units #{audit_units.count { |unit| !unit['needs_you'].empty? }}, non-project #{non_project_rows.size}"
		puts "edges: #{final.size} total — #{conf_counts.sort.to_h}; by type #{type_counts.sort.to_h}"
		calibration.each { |c| puts "calibration: #{c['pair']} — #{c['confidence']} #{c['types']}, same_cluster=#{c['same_cluster']}" }
		puts "wrote #{OUT_YAML}"
		puts "wrote #{OUT_MD}"
	end

	INSTRUCTIONS = <<~'TEXT'
		## How to review this sheet

		You are looking at derived views of machine proposals and durable rulings.
		Record rulings in `decisions.jsonl`; do not edit the regenerated YAML or
		Markdown directly. The ledger is authoritative; these sheets regenerate.

		A **complex** contains two or more records; a **singleton** contains one.
		Each complex or singleton is an **audit unit**. Either may represent a
		project, work, software output, or other endeavour: those types do not
		determine how many records an audit unit contains.

		### The fields you fill in: `gate:` and `containment:`

		Rulings come in two **orthogonal channels**: membership (do these records
		belong to the same complex?) and containment (is one document part of
		another?). A pair can carry one ruling in each channel independently.

		Every proposed link ("edge") between two items ends with a `gate:` field —
		the **membership** ruling. Type ONE word after it:

		- `same-project` — legacy serialized value meaning the records form one complex
		- `describes` — one talks about the other; the records remain separate audit
		  units whether or not they concern the same genuine endeavour
		- `implements` — one is software implementing the other's ideas
		- `cites` — one merely cites the other
		- `unrelated` — the machine is wrong
		- `siblings` — co-container or co-commentary context without joining the
		  records into one complex; this does not decide endeavour identity.
		  Cuts like `unrelated` but keeps the distinction in the record

		Only `same-project` edges weld records into complexes. Blank = undecided =
		treated as not-same-project. `gate:` also appears on candidate links.

		The `containment:` field appears when a ruling exists: `part-of` (one is
		contained in the other) or `unrelated` (the proposed containment is wrong).
		Edges whose detail says `container contained-in-book` come pre-typed
		`containment: part-of`; correct a wrong one by retyping `containment:
		unrelated`. Containment NEVER creates a complex. `container` edges between
		chapters record shared-volume context.

		### What to check, top to bottom

		1. **Complexes** — do the records form one multi-record audit unit? Record
		   membership rulings in the decisions ledger.
		2. **Singletons** — one-record audit units, including anchored singletons that
		   retain EP IDs from earlier gates. Anchoring does not change the record's EP ID.
		3. **Expected-artifact inventories** — every complex and singleton has one.
		   Append `inventory` rulings to the ledger: `required` or `optional` confirms
		   an entry with `proposed: false`; `not-expected` removes it on regeneration.
		4. **Non-project proposals** — the retained exclusion token for records outside
		   the audit-unit population, not a judgment about intellectual project-hood.

		### Authority

		The append-only ledger is authoritative. YAML and Markdown are derived views.
	TEXT

	# Renders the human-readable companion sheet.
	def render_markdown(sheet, final, by_key)
		g = sheet['generated_from']
		o = String.new
		o << "# #{sheet['sheet']} — Emerging Philosophy record clustering\n\n"
		o << "Snapshot: `#{g['snapshot']}` (sha256 `#{g['snapshot_sha256'][0, 16]}…`, library version #{g['library_version']}), "
		o << "population #{g['population']} top-level items. Orphan register: **#{g['orphan_register']}**.\n\n"
		o << INSTRUCTIONS
		o << "\n"
		o << "Clustering: #{sheet['parameters']['clustering']}. All edges are proposals; "
		o << "fill `gate` with a membership ruling (`same-project | describes | implements | cites | unrelated`) "
		o << "and `containment` with a containment ruling (`part-of | unrelated`) — the channels are orthogonal. "
		o << "Only confirmed `same-project` edges define complexes at the gate (§4.3).\n\n"

		o << "## Calibration (known true pairs)\n\n"
		sheet['calibration'].each do |c|
			o << "- #{c['pair']}: **#{c['confidence']}** (#{c['types'].join(' + ')}), same audit unit: #{c['same_cluster']}\n"
		end
		o << "\n"

		complexes = sheet['proposed_clusters'].select { |unit| unit['grouping'] == 'complex' }
		anchored_singletons = sheet['proposed_clusters'].select { |unit| unit['grouping'] == 'singleton' }
		[['Complexes', complexes], ['Anchored singletons', anchored_singletons]].each do |label, units|
			o << "## #{label} (#{units.size})\n\n"
			units.each do |p|
				o << "### #{p['id']} — #{p['proposed_name']} (proposed name, display-only)\n\n"
				o << "Grouping: #{p['grouping']}; members: #{p['members'].size}; earliest year: #{p['earliest_year'] || '????'}\n\n"
			p['needs_you'].each { |f| o << "- **NEEDS-YOU**: #{f}\n" }
			o << "\n" unless p['needs_you'].empty?
			p['members'].each do |m|
				o << "- `#{m['key']}` [#{m['role']}·#{m['role_confidence']}] #{m['year'] || '????'} — #{m['title']}#{m['url_host'].empty? ? '' : " (#{m['url_host']})"}\n"
			end
			o << "\nEdges (type, confidence, evidence):\n"
			p['edges'].each { |e| o << "- `#{e['a']}` ↔ `#{e['b']}` — #{e['confidence']}: #{e['detail']}\n" }
			unless p['candidate_links'].empty?
				o << "\nCandidate links (not clustered; cross-references after gate):\n"
				p['candidate_links'].each do |l|
					o << "- `#{l['member']}` → `#{l['other_key']}`#{l['to_project'] ? " (#{l['to_project']})" : ''} #{l['other_title']} — #{l['confidence']}: #{l['detail']}\n"
				end
			end
			o << "\nInventory proposals (§2.2, all `proposed`):\n"
			p['inventory'].each { |i| o << "- `#{i['id']}` [#{i['requirement']}] — #{i['basis']}\n" }
			o << "\n"
			end
		end

		o << "## Unanchored singletons (#{sheet['singletons'].size})\n\n"
		sheet['singletons'].each do |s|
			o << "### #{s['id']} — #{s['title']}\n\n"
			o << "- `#{s['key']}` [#{s['role']}·#{s['role_confidence']}] #{s['year'] || '????'}#{s['url_host'].empty? ? '' : " (#{s['url_host']})"}\n"
			s['needs_you'].each { |flag| o << "- **NEEDS-YOU**: #{flag}\n" }
			unless s['candidate_links'].empty?
				o << "\nCandidate links:\n"
				s['candidate_links'].each do |link|
					o << "- `#{link['to']}`#{link['to_project'] ? " (#{link['to_project']})" : ''} #{link['to_title']} — #{link['confidence']}: #{link['detail']}\n"
				end
			end
			o << "\nInventory proposals (§2.2, all `proposed`):\n"
			s['inventory'].each { |entry| o << "- `#{entry['id']}` [#{entry['requirement']}] — #{entry['basis']}\n" }
			o << "\n"
		end

		o << "\n## Non-project proposals (#{sheet['non_project'].size}) — NEEDS-YOU confirm\n\n"
		sheet['non_project'].each do |n|
			o << "- `#{n['key']}` [#{n['role']}·#{n['role_confidence']}] #{n['year'] || '????'} — #{n['title']} — #{n['reason']}\n"
		end

		o << "\n## Suppressed noisy tags (>#{TAG_MAX_BEARERS} bearers)\n\n"
		sheet['suppressed_tags'].each { |t| o << "- #{t['tag']} (#{t['bearers']})\n" }
		o << "\n## ID log (§2.4)\n\n"
		if sheet['id_log'].empty?
			o << "(empty — no merges or splits yet)\n"
		else
			sheet['id_log'].each do |l|
				o << "- #{l['id']} (#{l['date']}): #{l['reason']}#{l['successor'] ? " → #{l['successor']}" : ''}\n"
			end
		end
		o
	end
end

ZoteroCluster.run if __FILE__ == $PROGRAM_NAME
