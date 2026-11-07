#!/usr/bin/env ruby

require "optparse"
require "active_support/core_ext/numeric/bytes"
require_relative "../app/lib/security_config"
require_relative "../lib/zotero/client"
require_relative "zotero_inventory_audit"
require_relative "../lib/zotero/acquisition"

module ZoteroAcquire
  ROOT = File.expand_path("..", __dir__)
  OUTPUT = File.join(ROOT, "sources/emerging_philosophy/acquisition")

  module_function

  def routes(options)
    snapshot = ZoteroInventoryAudit::Snapshot.new(options[:snapshot])
    artifacts = ZoteroInventoryAudit::Inventory.new(options[:sheet], snapshot, snapshot_path: options[:snapshot]).artifacts
    results = ZoteroInventoryAudit.resume_results(options[:csv], artifacts)
    results = ZoteroInventoryAudit.apply_overrides(results, options[:overrides])
    results.map do |result|
      ZoteroAcquisition::Route.new(
        artifact_id: result.id,
        audit_unit: result.unit_id,
        requirement: result.requirement,
        status: result.status,
        route: result.route,
        evidence_url: result.evidence_url,
        evidence: result.evidence,
        attachment_key: result.attachment_key,
        item_title: result.item_title,
        source_url: result.source_url,
        expectations: expectations(result, snapshot)
      )
    end
  end

  def expectations(result, snapshot)
    if result.id == "EP-004/software/site"
      return {
        "media_type" => "text/html",
        "size" => 401_245,
        "sha256" => "7f152ca593a927da365db05636f8d87895339273b349601c026888b9d567a529",
        "html_markers" => ["DIALOG1", "Euthyphro"],
        "anchor_count" => 262,
        "version_edition" => "2016 web implementation; distinct from the unlocated 1990/1992 LEVEL5 original",
        "qualifications" => ["Does not supply EP-004/software/original"]
      }
    end
    return scan_expectations(result.evidence_url) if result.route == "local-file" && result.evidence_url.include?("/chapters/")

    if result.id == "EP-038/software/site"
      return {
        "media_type" => "text/html",
        "sha256" => "2ef29a3eceb5df9022a6bf6f34623ea770d71c3ed5f1566472a3b937da85ad26",
        "html_markers" => ["OSCAR", "defeasible"],
        "version_edition" => "OSCAR project page, banner 2013-09-17"
      }
    end
    return oscar_directory_expectations(result) if result.route == "local-directory"

    expectations = {}
    if result.route == "zotero-stored-pdf"
      attachment = snapshot.by_key.fetch(result.attachment_key)
      expectations["media_type"] = "application/pdf"
      expectations["title"] = result.item_title
      expectations["size"] = attachment.dig("links", "enclosure", "length")
      expectations["md5"] = attachment.dig("data", "md5")
      expectations["version_edition"] = "Zotero attachment #{result.attachment_key}, snapshot version #{attachment["version"]}"
      expectations.merge!(attachment_content_expectations(result.id))
    elsif result.route == "local-file"
      expectations["media_type"] = (File.extname(result.evidence_url.to_s).downcase == ".pdf") ? "application/pdf" : "text/html"
      expectations["title"] = result.item_title if expectations["media_type"] == "application/pdf"
    else
      expectations.merge!(attachment_content_expectations(result.id))
    end
    expectations.reject { |_, value| value.nil? || value.to_s.empty? }
  end

  def attachment_content_expectations(artifact_id)
    case artifact_id
    when "EP-020/visualization/main"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The live Tableau dashboard is JavaScript-dependent; a static HTML response does not preserve or verify the working visualization."
        },
        "qualifications" => ["The dashboard's interactive behavior remains unacquired"]
      }
    when "EP-013/book/main", "EP-013/book/other-1"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The WAB issue index links to article-level full texts but is not itself the complete proceedings volume."
        },
        "qualifications" => ["Only the issue index was retrieved; the complete volume remains unacquired"]
      }
    when "EP-003/paper/other-1", "EP-036/book/main"
      {
        "pages" => 287,
        "text_pages" => 42,
        "content_review" => {
          "status" => "passed",
          "evidence" => "The complete 1996 Logical Reasoning with Diagrams volume contains the Barwise/Etchemendy reprint 'Visual Information and Valid Reasoning', printed pp. 3-25 at PDF pages 20-42; the chapter opening and concluding page were inspected."
        },
        "version_edition" => "1996 reprint in Logical Reasoning with Diagrams, printed pp. 3-25",
        "qualifications" => ["The physical object is the complete 287-page volume containing the required chapter, not a standalone chapter extraction"]
      }
    when "EP-007/book/main"
      {
        "title" => "Language, Proof and Logic",
        "pages" => 620,
        "sha256" => "38ece1f96b02434c479f5b67dd6003bd829473171b5061340b9ceb0e63cd2d8d",
        "local_path" => "sources/emerging_philosophy/deep-dive/artifacts/lpl/lpl-2nd-edition.pdf",
        "content_review" => {
          "status" => "passed",
          "evidence" => "The preserved 620-page 2011 second edition identifies Dave Barker-Plummer, Jon Barwise, and John Etchemendy and ISBN 978-1-57586-632-1; the live direct route now supplies only a University of Cincinnati maintenance page."
        },
        "version_edition" => "2011 second edition, preserved from Wayback capture 2026-10-11 03:14:36 of the direct UC route",
        "qualifications" => ["Acquired from the verified preserved local copy after the live direct URL redirected to a maintenance page"]
      }
    when "EP-007/book/other-1"
      {
        "title" => "Language, Proof and Logic",
        "pages" => 597,
        "sha256" => "9063c5338c8eed8bdde646046b9d7006455008ad4d29fc097f7bc59c5b103d5f",
        "content_review" => {
          "status" => "passed",
          "evidence" => "The 597-page 1999 first-edition press PDF identifies Jon Barwise and John Etchemendy and matches the independently preserved copy and checksum."
        },
        "version_edition" => "1999 first edition"
      }
    when "EP-007/software/site"
      {
        "media_type" => "text/html",
        "size" => 20_036,
        "sha256" => "7d6c09729442b400cf762fed96c51b6f804680db96066cfbb0f95102a71658c5",
        "local_path" => "sources/emerging_philosophy/deep-dive/artifacts/lpl/lpl-features-20190722-capture.html",
        "html_markers" => ["Openproof Courseware: Language, Proof and Logic", "Features", "Tarski's World", "Fitch", "Boole", "Submit"],
        "content_review" => {
          "status" => "passed",
          "evidence" => "The preserved 2019 LPL Features page enumerates Tarski's World, Fitch, Boole, Submit, and the Grade Grinder; the live ggweb route now serves the replacement Openproof Courseware home."
        },
        "version_edition" => "LPL Features page, Wayback capture 2019-07-22 01:54:12",
        "qualifications" => ["Static page preservation; does not supply the registration-gated desktop software binaries"]
      }
    when "EP-003/software/site"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The 765-byte response is only a JavaScript redirect to the LRDS product page; it does not supply or verify the Hyperproof project page itself."
        },
        "qualifications" => ["Only the redirect shell was retrieved; the destination remains unacquired"]
      }
    when "EP-006/software/site"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The route supplies a generic 'The Logic Web Site' username/password page with no SYMLOG identity or project content; it does not verify the expected SYMLOG homepage or software."
        }
      }
    when "EP-008/software/site"
      {
        "html_markers" => ["PhiloSURFical", "Semantically browse a philosophical text", "Wittgenstein"],
        "version_edition" => "PhiloSURFical project archive at The Open University"
      }
    when "EP-009/software/site", "EP-009/software/other-1"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "Both DAPHNET routes now supply the same unrelated 'All US States - Short Term Loans Info Board Online' spam page, not Ancient or Early Modern Philosophy Source."
        }
      }
    when "EP-011/software/site"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The archived Philosophy Published Subject Set supplies dataset content but does not recover the visualization interface; the interface remains unacquired."
        },
        "version_edition" => "Archived Philosophy Published Subject Set dataset, not the Knowledge Map interface",
        "qualifications" => ["Dataset preservation must not be counted as interface recovery"]
      }
    when "EP-012/software/site"
      {
        "media_type" => "application/rdf+xml",
        "text_markers" => ["rdf:RDF", "Philosophy ontology", "Philosophical_field"],
        "content_review" => {
          "status" => "passed",
          "evidence" => "The 261,641-byte RDF/XML document parses with an RDF root, declares the title 'Philosophy ontology', and contains the expected philosophical-field hierarchy from the pdcphilontology-v1.owl route."
        },
        "version_edition" => "PDC Philosophy Ontology version 1 OWL/RDF"
      }
    when "EP-012/web/site"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The archived Philosophome response is only a frameset wrapper pointing to ontology.buffalo.edu/philosophome; the framed homepage content was not acquired."
        },
        "qualifications" => ["The frameset wrapper alone is not counted as recovery of the homepage"]
      }
    when "EP-021/software/site"
      {
        "html_markers" => ["Digital Ricoeur", "Ricoeur's works", "search terms"],
        "version_edition" => "Live Digital Ricoeur project/about page"
      }
    when "EP-022/software/site"
      {
        "html_markers" => ["Distant Reading and Data-Driven Research", "DR2 Research Group", "University of Turin"],
        "version_edition" => "Live DR2 research-group blog"
      }
    when "EP-024/software/site"
      {
        "html_markers" => ["History of Philosophy - Summarized & Visualized", "Deniz Cem Önduygu"],
        "version_edition" => "Live History of Philosophy browse page",
        "qualifications" => ["Static HTML preservation; interactive visualization behavior was not verified"]
      }
    when "EP-047/software/site"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The 114-byte response only redirects to /lander and contains no Bazzocchi Tractatus project content."
        }
      }
    when "EP-048/web/site"
      {
        "html_markers" => ["Projects - ILPS", "A list of current and past projects"],
        "version_edition" => "ILPS Projects page, Wayback capture 2016-04-03"
      }
    when "EP-052/software/site"
      {
        "html_markers" => ["BoxStrapper", "wab_init", "murucaThemeInit"],
        "content_review" => {
          "status" => "passed",
          "evidence" => "The live Wittgenstein Source route supplies its OpenSeadragon/BoxStrapper front-end shell and WAB initialization code; this verifies the project shell, not the dynamically loaded content or a running interface."
        },
        "version_edition" => "Live Wittgenstein Source front-end shell",
        "qualifications" => ["Static front-end shell only; dynamic content and interactive behavior were not verified"]
      }
    when "EP-078/web/site"
      {
        "html_markers" => ["SEP Table of Contents", "collection of the summaries", "aaron kosel"],
        "content_review" => {
          "status" => "passed",
          "evidence" => "The archived page is Aaron Kosel's searchable collection of Stanford Encyclopedia of Philosophy article summaries, matching the Philosophy Summary project despite its 'SEP Table of Contents' page title."
        },
        "version_edition" => "Philosophy Summary, Wayback capture 2013-06-15",
        "qualifications" => ["Static page preservation; search behavior was not verified"]
      }
    when "EP-021/paper/other-1", "EP-105/paper/main"
      {
        "pages" => 9,
        "text_pages" => 9,
        "content_review" => {
          "status" => "failed",
          "evidence" => "The nine-page EADH 2018 draft programme contains only a session listing for 'Digital Ricoeur Data Model' by Philip McGrath and Fernando Nascimento at 11:00 on PDF page 4; it supplies neither the full paper nor an abstract."
        },
        "version_edition" => "EADH 2018 draft programme, 5 December 2018; programme listing only",
        "qualifications" => ["Only the programme entry is preserved; the paper text remains unacquired"]
      }
    when "EP-129/paper/main"
      {
        "content_review" => {
          "status" => "failed",
          "evidence" => "The route supplies Satoru Niki's 'Empirical Negation, Co-negation and Contraposition Rule I', not the expected Computer-Supported Analysis paper; OpenAlex W3048600824 identifies the same different work."
        },
        "version_edition" => "Route mismatch: Niki article, not the expected artifact"
      }
    when "EP-135/paper/main"
      {
        "html_markers" => ["Symbolic AI and Gödel's Ontological Argument", "A Computationally Explored Simplified Variant of the Ontological Argument", "References"],
        "content_review" => {
          "status" => "passed",
          "evidence" => "Zygon supplies full HTML text with substantive sections 'Artificial Intelligence (AI): Symbolic versus Subsymbolic', 'A Computationally Explored Simplified Variant of the Ontological Argument', 'Metaphysics and Rational Theology as an Experimental Science?', Notes, and References; not merely an abstract."
        },
        "version_edition" => "Zygon full HTML article at zygonjournal.org"
      }
    when "EP-003/book/main"
      {
        "title" => nil,
        "pages" => 4,
        "ocr_pages" => [1, 4],
        "ocr_dpi" => 200,
        "ocr_markers" => ["About Hyperproof", "Contents"],
        "content_review" => {
          "status" => "failed",
          "evidence" => "The four pages are only the table of contents (pp. ix-xii); the complete Hyperproof book is not supplied."
        },
        "version_edition" => "Hyperproof table-of-contents excerpt, not the complete 1994 book",
        "qualifications" => ["Only four table-of-contents pages (ix-xii); the full book remains unacquired"]
      }
    when "EP-028/book/main"
      {"title" => "The Computer Revolution in Philosophy"}
    when "EP-060/paper/main", "EP-065/paper/main"
      {
        "title" => nil,
        "pages" => 5,
        "ocr_pages" => [1],
        "ocr_dpi" => 200,
        "ocr_markers" => ["A Model for Philosophers", "Stephen Crowley"],
        "version_edition" => "AAAI FSS-11-03 paper; printed title omits the Zotero NEH Panel prefix"
      }
    when "EP-077/paper/main"
      {"title" => "Overlapping and Competing Ontologies"}
    when "EP-106/paper/main"
      {"text_pages" => 10}
    else
      {}
    end
  end

  def scan_expectations(path)
    basename = File.basename(path)
    configuration = case basename
    when /^ch12-/
      [5, ["Mouse-Driven", "Croy", "Amidon", "213", "Deductive Proof Construction"], "printed pp. 213-217"]
    when /^ch13-/
      [11, ["PROOF DESIGNER", "Bedau", "Moor", "228"], "printed pp. 218-228"]
    when /^ch14-/
      [6, ["Designing", "Finite Structures", "Portoraro", "234"], "printed pp. 229-234"]
    when /^ch15-/
      [12, ["Socratic Dialogue", "Don Barker", "Stephen Scott", "246"], "printed pp. 235-246"]
    else
      raise ArgumentError, "no scan verification configuration for #{basename}"
    end
    pages, markers, edition = configuration
    {
      "media_type" => "application/pdf",
      "pages" => pages,
      "ocr_pages" => [1, pages],
      "ocr_dpi" => 200,
      "ocr_markers" => markers,
      "version_edition" => "Burkholder volume chapter scan, #{edition}",
      "qualifications" => ["Image-only scan; first/last-page OCR plus documented full-chapter reading"]
    }
  end

  def oscar_directory_expectations(result)
    directory = File.basename(result.evidence_url)
    files = oscar_expected_files(directory)
    expectations = {
      "files" => files,
      "file_count" => files.size,
      "version_edition" => (directory == "CODE") ? "OSCAR 3.31 distribution" : "OSCAR Manual chapters 1-7 and appendices 1-2"
    }
    if directory == "CODE"
      expectations["content_markers"] = {"OSCAR_3-31.lisp" => ["*version* \"OSCAR_3.31\""]}
      expectations["software_version"] = "OSCAR_3.31"
    end
    expectations
  end

  def oscar_expected_files(directory)
    manifest = File.join(ROOT, "sources/emerging_philosophy/deep-dive/artifacts/oscar/MANIFEST-sha256.txt")
    expected = {}
    File.foreach(manifest) do |line|
      sha256, path = line.strip.split(/\s+/, 2)
      next unless path&.start_with?("#{directory}/")
      expected[path.sub(/\A#{Regexp.escape(directory)}\//, "")] = sha256
    end
    raise ArgumentError, "no OSCAR manifest entries for #{directory}" if expected.empty?
    expected
  end

  def select_routes(routes, only: [], statuses: [])
    unknown = only - routes.map(&:artifact_id)
    raise ArgumentError, "unknown artifact IDs: #{unknown.join(", ")}" unless unknown.empty?
    unknown_statuses = statuses - routes.map(&:status).uniq
    raise ArgumentError, "unknown statuses: #{unknown_statuses.join(", ")}" unless unknown_statuses.empty?
    selected = only.empty? ? routes : routes.select { |route| only.include?(route.artifact_id) }
    return selected if statuses.empty?
    selected.select { |route| statuses.include?(route.status) }
  end

  def run(options)
    all_routes = routes(options)
    selected = select_routes(all_routes, only: options[:only], statuses: options[:statuses])
    store = ZoteroAcquisition::Store.new(options[:output])
    remote_fetcher = ZoteroAcquisition::RemoteFetcher.new
    git_fetcher = ZoteroAcquisition::GitFetcher.new
    runner = ZoteroAcquisition::Runner.new(store, remote_fetcher: remote_fetcher, git_fetcher: git_fetcher)
    fetcher = nil

    if options[:verify_only]
      checks = selected.map do |route|
        slot = store.read_slot(route.artifact_id)
        verified = runner.resumable?(slot)
        puts [route.artifact_id, verified ? "verified" : "not-resumable"].join(" ")
        verified
      end
      coverage = runner.finalize(all_routes)
      raise "one or more selected objects failed verification" unless checks.all?
      return coverage
    end

    if selected.any? { |route| route.status == "present" && route.route == "zotero-stored-pdf" }
      Zotero.load_env_file
      credentials = Zotero.credentials
      fetcher = ZoteroAcquisition::AttachmentFetcher.new(user_id: credentials[:user_id], api_key: credentials[:api_key])
      runner = ZoteroAcquisition::Runner.new(store, attachment_fetcher: fetcher, remote_fetcher: remote_fetcher, git_fetcher: git_fetcher)
    end

    results = selected.map do |route|
      result = runner.process(route)
      puts [result.artifact_id, result.action, result.terminal_status, result.object_id, result.error].compact.join(" ")
      result
    end
    coverage = runner.finalize(all_routes)
    puts "Physical objects: #{store.objects.size}"
    puts "Zotero attachment downloads: #{fetcher ? fetcher.fetch_count : 0}"
    puts "Other remote downloads: #{remote_fetcher.fetch_count}"
    puts "Git clones: #{git_fetcher.fetch_count}"
    puts "Required: #{coverage.dig("required", "satisfied")}/#{coverage.dig("required", "total")} satisfied; #{coverage.dig("required", "missing")} missing"
    puts "Pending slots: #{coverage.fetch("slots").count { |slot| slot["status"] == "pending" }}"
    puts "Phase 3 complete: #{coverage["complete"]}"
    raise "one or more selected acquisitions failed" if results.any? { |result| result.terminal_status == "failed" }
    coverage
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    sheet: ZoteroInventoryAudit::SHEET,
    snapshot: ZoteroInventoryAudit::SNAPSHOT,
    csv: ZoteroInventoryAudit::OUT_CSV,
    overrides: ZoteroInventoryAudit::OVERRIDES,
    output: ZoteroAcquire::OUTPUT,
    only: [],
    statuses: [],
    verify_only: false
  }
  OptionParser.new do |parser|
    parser.on("--sheet PATH") { |path| options[:sheet] = path }
    parser.on("--snapshot PATH") { |path| options[:snapshot] = path }
    parser.on("--csv PATH") { |path| options[:csv] = path }
    parser.on("--overrides PATH") { |path| options[:overrides] = path }
    parser.on("--output DIR") { |path| options[:output] = path }
    parser.on("--only ARTIFACT_ID") { |id| options[:only] << id }
    parser.on("--status STATUS") { |status| options[:statuses] << status }
    parser.on("--verify") { options[:verify_only] = true }
  end.parse!
  ZoteroAcquire.run(options)
end
