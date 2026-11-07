require "test_helper"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"
require_relative "../../lib/zotero/acquisition"
require_relative "../../scripts/zotero_acquire"

class ZoteroAcquisitionTest < ActiveSupport::TestCase
  ROOT = File.expand_path("../..", __dir__)
  PDF_SOURCE = File.join(ROOT, "sources/emerging_philosophy/deep-dive/artifacts/oscar/PAPERS/Rational-Cognition-in-OSCAR.pdf")
  SCAN_SOURCE = File.join(ROOT, "sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch13-bedau-moor-proof-designer_pp218-228.pdf")
  PDF_TITLE = "Rational Cognition in OSCAR"

  class FakeAttachmentFetcher
    attr_reader :calls

    def initialize(source)
      @source = source
      @calls = []
    end

    def fetch(key, destination)
      @calls << key
      FileUtils.cp(@source, destination)
      {
        "source_urls" => ["https://api.zotero.test/users/1/items/#{key}/file"],
        "final_url" => "https://files.zotero.test/#{key}",
        "fetched_at" => "2026-10-26T00:00:00Z",
        "attempts" => [{"method" => "GET", "http_status" => 200, "url" => "https://api.zotero.test/#{key}"}]
      }
    end
  end

  class FakeGitFetcher
    attr_reader :calls

    def initialize(source)
      @source = source
      @calls = []
    end

    def clone(url, destination)
      @calls << url
      FileUtils.cp_r(@source, destination)
      {
        "success" => true,
        "source_urls" => [url],
        "final_url" => url,
        "fetched_at" => "2026-10-28T00:00:00Z",
        "attempts" => [{"method" => "GIT CLONE", "url" => url, "exit_status" => 0}],
        "clone_status" => {"exit_status" => 0}
      }
    end
  end

  setup do
    @directory = Dir.mktmpdir
    @store = ZoteroAcquisition::Store.new(@directory)
    @runner = ZoteroAcquisition::Runner.new(@store)
    @pdf = File.join(@directory, "source.pdf")
    FileUtils.cp(PDF_SOURCE, @pdf)
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "slot manifests accept all terminal states and reject incomplete outcomes" do
    ZoteroAcquisition::TERMINAL_STATUSES.each do |status|
      manifest = slot_manifest(status)
      assert_equal status, manifest.fetch("terminal_status")
      assert ZoteroAcquisition::Manifest.validate_slot!(manifest)
    end

    assert_raises(ArgumentError) { slot_manifest("unresolved") }
    assert_raises(ArgumentError) { slot_manifest("failed", evidence: "") }
    assert_raises(ArgumentError) { slot_manifest("absent-expected", evidence: "") }
    assert_raises(ArgumentError) { slot_manifest("acquired", object_id: nil) }
  end

  test "two local slots share one physical object" do
    routes = [local_route("EP-001/paper/main"), local_route("EP-030/book/main")]

    routes.each { |route| @runner.process(route) }
    @runner.finalize(routes)

    assert_equal 1, @store.objects.size
    assert_equal 2, @store.slots.size
    assert_equal [@store.objects.first.fetch("object_id")], @store.slots.map { |slot| slot.fetch("object_id") }.uniq
    assert_equal routes.map(&:artifact_id).sort, @store.objects.first.fetch("slot_ids").sort
    assert_equal 1, @store.registry.fetch("objects").size
  end

  test "local verification attempts survive an eventual success" do
    failed_route = local_route("EP-001/paper/main")
    failed_route.expectations = pdf_expectations.merge("title" => "Wrong Paper")
    successful_route = local_route("EP-001/paper/main")
    @runner.process(failed_route)

    result = @runner.process(successful_route)

    assert_equal "acquired", result.terminal_status
    attempts = @store.read_slot(successful_route.artifact_id).fetch("attempts")
    assert_equal 2, attempts.size
    assert_equal %w[failed passed], attempts.map { |attempt| attempt.fetch("status") }
  end

  test "shared Zotero attachment is fetched once and linked from both slots" do
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, attachment_fetcher: fetcher)
    routes = [attachment_route("EP-027/paper/main"), attachment_route("EP-131/paper/main")]

    routes.each { |route| assert_equal "acquired", runner.process(route).terminal_status }
    runner.finalize(routes)

    assert_equal ["CHH5MUHB"], fetcher.calls
    assert_equal 1, @store.objects.size
    assert_equal 1, Dir.glob(File.join(@directory, "objects", "**", "*.pdf")).size
    assert_equal routes.map(&:artifact_id).sort, @store.objects.first.fetch("slot_ids").sort
    assert_equal 2, @store.slots.count { |slot| slot.fetch("terminal_status") == "acquired" }
  end

  test "valid acquired attachment resumes without another fetch" do
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, attachment_fetcher: fetcher)
    route = attachment_route("EP-027/paper/main")
    runner.process(route)

    result = runner.process(route)

    assert_equal "skipped", result.action
    assert_equal ["CHH5MUHB"], fetcher.calls
  end

  test "corrupted acquired attachment is fetched again and attempt history survives" do
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, attachment_fetcher: fetcher)
    route = attachment_route("EP-027/paper/main")
    runner.process(route)
    object = @store.objects.first
    File.open(@store.expand_path(object.fetch("path")), "ab") { |file| file.write("corruption") }

    result = runner.process(route)

    assert_equal "acquired", result.terminal_status
    assert_equal ["CHH5MUHB", "CHH5MUHB"], fetcher.calls
    assert_equal 2, @store.read_slot(route.artifact_id).fetch("attempts").size
  end

  test "PDF verification checks structure identity and extent" do
    result = file_verifier.verify(@pdf, pdf_expectations)

    assert_equal "passed", result.fetch("status")
    assert_equal File.size(@pdf), result.fetch("size")
    assert_equal Digest::SHA256.file(@pdf).hexdigest, result.fetch("sha256")
    assert_equal 20, result.dig("extent", "pages")
    assert_equal true, result.dig("identity", "title_matched")
    assert_equal "John L. Pollock", result.dig("format", "author")
  end

  test "wrong PDF title and invalid PDF bytes fail verification" do
    wrong_title = file_verifier.verify(@pdf, pdf_expectations.merge("title" => "A Different Paper"))
    assert_equal "failed", wrong_title.fetch("status")
    assert_equal false, wrong_title.dig("identity", "title_matched")

    invalid = File.join(@directory, "invalid.pdf")
    File.write(invalid, "%PDF-not really a PDF")
    result = file_verifier.verify(invalid, pdf_expectations)
    assert_equal "failed", result.fetch("status")
    assert result.fetch("checks").any? { |check| check.fetch("name") == "pdfinfo" && check.fetch("status") == "failed" }
  end

  test "checksum and byte-size mismatches fail file verification" do
    result = file_verifier.verify(@pdf, pdf_expectations.merge("sha256" => "0" * 64, "size" => 12))

    assert_equal "failed", result.fetch("status")
    assert_equal %w[failed failed], result.fetch("checks").first(2).map { |check| check.fetch("status") }
  end

  test "HTML verification handles legacy bytes and excludes metadata from named anchors" do
    path = File.join(@directory, "dialog.html")
    content = "<html><title>DIALOG1</title><meta name='description' content='test'><a name='aR3'>Socratic</a><a name='fCC1'>Rule\x94</a></html>"
    File.binwrite(path, content.b)

    result = file_verifier.verify(path, "media_type" => "text/html", "html_markers" => ["DIALOG1", "Socratic"], "anchor_count" => 2)

    assert_equal "passed", result.fetch("status")
    assert_equal 2, result.dig("format", "named_anchors")
  end

  test "XML verification parses RDF and checks identifying markers" do
    path = File.join(@directory, "ontology.owl")
    File.write(path, '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="philosophy"/></rdf:RDF>')

    result = file_verifier.verify(path, "media_type" => "application/rdf+xml", "text_markers" => ["rdf:RDF", "philosophy"])

    assert_equal "passed", result.fetch("status")
    assert_equal true, result.dig("identity", "markers_matched")
    File.write(path, "<rdf:RDF>")
    assert_equal "failed", file_verifier.verify(path, "media_type" => "application/rdf+xml").fetch("status")
  end

  test "image-only PDF uses OCR for identity and exact page count" do
    result = file_verifier.verify(
      SCAN_SOURCE,
      "media_type" => "application/pdf",
      "pages" => 11,
      "ocr_pages" => [1, 11],
      "ocr_dpi" => 200,
      "ocr_markers" => ["PROOF DESIGNER", "Bedau", "228"]
    )

    assert_equal "passed", result.fetch("status")
    assert_equal 11, result.dig("extent", "pages")
    assert_equal true, result.dig("identity", "ocr_markers_matched")
    assert result.fetch("checks").any? { |check| check.fetch("name") == "pdf_page_count" && check.fetch("status") == "passed" }
  end

  test "missing PDF tools are unavailable rather than artifact failures" do
    verifier = file_verifier
    verifier.define_singleton_method(:command) { |*| nil }

    result = verifier.verify(@pdf, "media_type" => "application/pdf")

    assert_equal "passed", result.fetch("status")
    statuses = result.fetch("checks").to_h { |check| [check.fetch("name"), check.fetch("status")] }
    assert_equal "unavailable", statuses.fetch("pdfinfo")
    assert_equal "unavailable", statuses.fetch("pdftotext")
  end

  test "directory verification checks exact files hashes and content markers" do
    path, expectations = create_directory

    result = directory_verifier.verify(path, expectations)

    assert_equal "passed", result.fetch("status")
    assert_equal 2, result.fetch("file_count")
    assert_equal 2, result.fetch("files").size
    assert result.fetch("inventory_sha256").match?(/\A\h{64}\z/)

    File.write(File.join(path, "a.txt"), "tampered")
    assert_equal "failed", directory_verifier.verify(path, expectations).fetch("status")
    File.write(File.join(path, "a.txt"), "alpha")
    File.write(File.join(path, "extra.txt"), "extra")
    assert_equal "failed", directory_verifier.verify(path, expectations).fetch("status")
  end

  test "directory objects resume only while their current inventory passes" do
    path, expectations = create_directory
    object = directory_object(path, expectations)
    @store.write_object(object)
    slot = acquired_slot_for(object)
    @store.write_slot(slot)

    assert @runner.resumable?(slot)
    File.write(File.join(path, "a.txt"), "tampered")
    refute @runner.resumable?(slot)
  end

  test "shared object cannot bypass a different slot title" do
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, attachment_fetcher: fetcher)
    matching = attachment_route("EP-027/paper/main")
    different = attachment_route("EP-131/paper/main")
    different.expectations = pdf_expectations.merge("title" => "A Different Paper")
    runner.process(matching)

    result = runner.process(different)

    assert_equal "failed", result.terminal_status
    assert_equal ["CHH5MUHB"], fetcher.calls
    assert_equal "acquired", @store.read_slot(matching.artifact_id).fetch("terminal_status")
    assert_equal "failed", @store.read_slot(different.artifact_id).fetch("terminal_status")
  end

  test "failed attachment is preserved and reused after expectation correction" do
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, attachment_fetcher: fetcher)
    failed_route = attachment_route("EP-027/paper/main")
    failed_route.expectations = pdf_expectations.merge("title" => "Wrong Paper")
    corrected_route = attachment_route("EP-027/paper/main")
    runner.process(failed_route)

    assert_equal 1, @store.objects.size
    result = runner.process(corrected_route)

    assert_equal "acquired", result.terminal_status
    assert_equal ["CHH5MUHB"], fetcher.calls
    assert_equal 1, Dir.glob(File.join(@directory, "objects", "**", "*.pdf")).size
  end

  test "title normalization handles ligatures and configurable text extent" do
    assert_equal "digital ricoeur", file_verifier.send(:normalize, "Digital Ricœur")
    result = file_verifier.verify(@pdf, pdf_expectations.merge("text_pages" => 1))
    assert_equal 1, result.dig("extent", "text_pages")
  end

  test "documented content review can reject a partial artifact" do
    review = {"status" => "failed", "evidence" => "Only a table-of-contents excerpt"}
    result = file_verifier.verify(@pdf, pdf_expectations.merge("content_review" => review))

    assert_equal "failed", result.fetch("status")
    assert result.fetch("checks").any? { |check| check.fetch("name") == "content_review" && check.fetch("status") == "failed" }
  end

  test "curated expectations handle documented title variants and front matter" do
    routes = ZoteroAcquire.routes(
      sheet: ZoteroInventoryAudit::SHEET,
      snapshot: ZoteroInventoryAudit::SNAPSHOT,
      csv: ZoteroInventoryAudit::OUT_CSV,
      overrides: ZoteroInventoryAudit::OVERRIDES
    ).to_h { |route| [route.artifact_id, route] }

    assert_equal "The Computer Revolution in Philosophy", routes.fetch("EP-028/book/main").expectations.fetch("title")
    assert_equal "Overlapping and Competing Ontologies", routes.fetch("EP-077/paper/main").expectations.fetch("title")
    assert_equal ["A Model for Philosophers", "Stephen Crowley"], routes.fetch("EP-060/paper/main").expectations.fetch("ocr_markers")
    assert_equal 10, routes.fetch("EP-106/paper/main").expectations.fetch("text_pages")
    review = routes.fetch("EP-003/book/main").expectations.fetch("content_review")
    assert_equal "failed", review.fetch("status")
    assert_includes review.fetch("evidence"), "table of contents"
    full_text = routes.fetch("EP-135/paper/main").expectations.fetch("content_review")
    assert_equal "passed", full_text.fetch("status")
    assert_includes full_text.fetch("evidence"), "full HTML text"
    mismatch = routes.fetch("EP-129/paper/main").expectations.fetch("content_review")
    assert_equal "failed", mismatch.fetch("status")
    assert_includes mismatch.fetch("evidence"), "Satoru Niki"
    dashboard = routes.fetch("EP-020/visualization/main").expectations.fetch("content_review")
    assert_equal "failed", dashboard.fetch("status")
    assert_includes dashboard.fetch("evidence"), "JavaScript"
    %w[EP-013/book/main EP-013/book/other-1].each do |artifact_id|
      issue = routes.fetch(artifact_id).expectations.fetch("content_review")
      assert_equal "failed", issue.fetch("status")
      assert_includes issue.fetch("evidence"), "issue index"
    end
    reprint = routes.fetch("EP-036/book/main").expectations.fetch("content_review")
    assert_equal "passed", reprint.fetch("status")
    assert_includes reprint.fetch("evidence"), "PDF pages 20-42"
    programme = routes.fetch("EP-105/paper/main").expectations.fetch("content_review")
    assert_equal "failed", programme.fetch("status")
    assert_includes programme.fetch("evidence"), "PDF page 4"
    assert_equal 620, routes.fetch("EP-007/book/main").expectations.fetch("pages")
    assert_includes routes.fetch("EP-007/book/main").expectations.fetch("local_path"), "lpl-2nd-edition.pdf"
    assert_includes routes.fetch("EP-007/software/site").expectations.fetch("local_path"), "lpl-features-20190722-capture.html"
    knowledge_map = routes.fetch("EP-011/software/site").expectations.fetch("content_review")
    assert_equal "failed", knowledge_map.fetch("status")
    assert_includes knowledge_map.fetch("evidence"), "does not recover the visualization interface"
    assert_equal "application/rdf+xml", routes.fetch("EP-012/software/site").expectations.fetch("media_type")
    assert_includes routes.fetch("EP-012/software/site").expectations.fetch("text_markers"), "rdf:RDF"
    assert_includes routes.fetch("EP-008/software/site").expectations.fetch("html_markers"), "PhiloSURFical"
    philosophome = routes.fetch("EP-012/web/site").expectations.fetch("content_review")
    assert_equal "failed", philosophome.fetch("status")
    assert_includes philosophome.fetch("evidence"), "frameset wrapper"
  end

  test "status filter selects exactly the present inventory" do
    routes = ZoteroAcquire.routes(
      sheet: ZoteroInventoryAudit::SHEET,
      snapshot: ZoteroInventoryAudit::SNAPSHOT,
      csv: ZoteroInventoryAudit::OUT_CSV,
      overrides: ZoteroInventoryAudit::OVERRIDES
    )

    selected = ZoteroAcquire.select_routes(routes, statuses: ["present"])

    assert_equal 73, selected.size
    assert_equal 70, selected.count { |route| route.requirement == "required" }
    assert_equal 3, selected.count { |route| route.requirement == "optional" }
    assert(selected.all? { |route| route.status == "present" })
    assert_equal ["EP-004/software/site"], ZoteroAcquire.select_routes(routes, only: ["EP-004/software/site"], statuses: ["present"]).map(&:artifact_id)
  end

  test "OpenAlex slots share one URL object and resume without another fetch" do
    url = "https://www.nature.com/articles/shared.pdf"
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)
    routes = [remote_route("EP-022/paper/other-1", url: url), remote_route("EP-137/paper/main", url: url)]

    routes.each { |route| assert_equal "acquired", runner.process(route).terminal_status }
    runner.finalize(routes)

    assert_equal [url], fetcher.calls
    assert_equal 1, @store.objects.size
    assert_equal 2, @store.slots.size
    assert_equal "skipped", runner.process(routes.last).action
    assert_equal [url], fetcher.calls
  end

  test "updated slot expectations trigger re-verification without another fetch" do
    url = "https://www.nature.com/articles/shared.pdf"
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)
    route = remote_route("EP-135/paper/main", url: url)
    runner.process(route)
    route.expectations = route.expectations.merge(
      "content_review" => {"status" => "passed", "evidence" => "Full text reviewed"}
    )

    result = runner.process(route)

    assert_equal "acquired", result.action
    assert_equal [url], fetcher.calls
    assert_equal "Full text reviewed", @store.read_slot(route.artifact_id).dig("verification", "identity", "content_review", "evidence")
  end

  test "PDF format is detected from bytes rather than a filename suffix" do
    path = File.join(@directory, "download")
    FileUtils.cp(@pdf, path)

    result = file_verifier.verify(path, "title" => PDF_TITLE)

    assert_equal "passed", result.fetch("status")
    assert_equal 20, result.dig("extent", "pages")
    assert result.fetch("checks").any? { |check| check.fetch("name") == "pdf_magic" && check.fetch("status") == "passed" }
  end

  test "remote HTML acquisition requires full-text sections and rejects an abstract" do
    title = "Symbolic AI and Gödel's Ontological Argument"
    expectations = {"html_markers" => [title, "Introduction", "References"]}
    full_path = File.join(@directory, "full.html")
    File.write(full_path, "<html><title>#{title}</title><p>Abstract</p><p>Introduction</p><p>References</p></html>")
    fetcher = FakeAttachmentFetcher.new(full_path)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)

    result = runner.process(remote_route("EP-135/paper/main", url: "https://doi.org/10.1111/zygo.12830", expectations: expectations))

    assert_equal "acquired", result.terminal_status
    object = @store.objects.first
    assert_equal "text/html", object.fetch("media_type")
    assert object.fetch("path").end_with?(".html")

    abstract_path = File.join(@directory, "abstract.html")
    File.write(abstract_path, "<html><title>#{title}</title><p>Abstract</p></html>")
    abstract_fetcher = FakeAttachmentFetcher.new(abstract_path)
    abstract_runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: abstract_fetcher)
    abstract = abstract_runner.process(remote_route("EP-136/paper/main", url: "https://example.test/abstract", expectations: expectations))
    assert_equal "failed", abstract.terminal_status
  end

  test "remote HTTP failures preserve their attempt history" do
    downloader = Object.new
    downloader.define_singleton_method(:get) do |url, _destination|
      {
        "success" => false,
        "error" => "too many redirects",
        "attempts" => [{"method" => "GET", "url" => url, "http_status" => 302}]
      }
    end
    fetcher = ZoteroAcquisition::RemoteFetcher.new(downloader: downloader)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)

    result = runner.process(remote_route("EP-133/paper/main", url: "https://example.test/loop"))

    assert_equal "failed", result.terminal_status
    attempts = @store.read_slot(result.artifact_id).fetch("attempts")
    assert_equal 1, attempts.size
    assert_equal 302, attempts.first.fetch("http_status")
  end

  test "status filter selects exactly the OpenAlex inventory" do
    routes = ZoteroAcquire.routes(
      sheet: ZoteroInventoryAudit::SHEET,
      snapshot: ZoteroInventoryAudit::SNAPSHOT,
      csv: ZoteroInventoryAudit::OUT_CSV,
      overrides: ZoteroInventoryAudit::OVERRIDES
    )

    selected = ZoteroAcquire.select_routes(routes, statuses: ["oa-resolvable"])

    assert_equal 8, selected.size
    assert_equal 7, selected.count { |route| route.requirement == "required" }
    assert_equal 1, selected.count { |route| route.requirement == "optional" }
    assert_equal 7, selected.map(&:evidence_url).uniq.size
    assert_equal selected.find { |route| route.artifact_id == "EP-022/paper/other-1" }.evidence_url,
      selected.find { |route| route.artifact_id == "EP-137/paper/main" }.evidence_url
  end

  test "reference and manual outcomes preserve required coverage and pending work" do
    reference = terminal_route("EP-016/visualization/main", "reference-only", "required")
    manual = terminal_route("EP-011/paper/other-1", "manual", "optional")
    pending = terminal_route("EP-040/book/main", "manual", "required")
    routes = [reference, manual, pending]
    @runner.process(reference)
    @runner.process(manual)

    coverage = @runner.finalize(routes)

    assert_equal 2, coverage.fetch("required").fetch("total")
    assert_equal 1, coverage.fetch("required").fetch("satisfied")
    assert_equal 1, coverage.fetch("required").fetch("by_status").fetch("pending")
    assert_equal 1, coverage.fetch("optional").fetch("by_status").fetch("manual")
    assert_equal false, coverage.fetch("complete")
    assert_equal "manual", @store.read_slot(manual.artifact_id).fetch("terminal_status")
  end

  test "direct URL acquisition detects PDF bytes and preserves the remote object" do
    url = "https://example.test/book-main"
    fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)
    route = terminal_route("EP-007/book/main", "direct", "required", route: "direct-url")
    route.evidence_url = url
    route.source_url = url
    route.item_title = PDF_TITLE
    route.expectations = {"title" => PDF_TITLE}

    result = runner.process(route)

    assert_equal "acquired", result.terminal_status
    assert_equal [url], fetcher.calls
    assert_equal "application/pdf", @store.objects.first.fetch("media_type")
    assert @store.objects.first.fetch("path").end_with?(".pdf")
  end

  test "direct local fallback replaces a superseded failed remote object" do
    url = "https://example.test/stale-book-route"
    maintenance = File.join(@directory, "maintenance.html")
    File.write(maintenance, "<html><title>Maintenance</title></html>")
    fetcher = FakeAttachmentFetcher.new(maintenance)
    runner = ZoteroAcquisition::Runner.new(@store, remote_fetcher: fetcher)
    route = terminal_route("EP-007/book/main", "direct", "required", route: "direct-url")
    route.evidence_url = url
    route.source_url = url
    route.item_title = PDF_TITLE
    route.expectations = {"title" => PDF_TITLE}
    failed = runner.process(route)
    failed_object_id = failed.object_id

    route.expectations = pdf_expectations.merge("local_path" => @pdf)
    result = runner.process(route)
    runner.finalize([route])

    assert_equal "failed", failed.terminal_status
    assert_equal "acquired", result.terminal_status
    assert_equal [url], fetcher.calls
    assert_equal 1, @store.objects.size
    assert_equal @pdf, @store.objects.first.fetch("path")
    refute File.exist?(@store.object_directory(failed_object_id))
    assert_equal %w[GET VERIFY], @store.read_slot(route.artifact_id).fetch("attempts").map { |attempt| attempt["method"] }
  end

  test "status filter selects exactly the direct URL inventory" do
    routes = ZoteroAcquire.routes(
      sheet: ZoteroInventoryAudit::SHEET,
      snapshot: ZoteroInventoryAudit::SNAPSHOT,
      csv: ZoteroInventoryAudit::OUT_CSV,
      overrides: ZoteroInventoryAudit::OVERRIDES
    )

    selected = ZoteroAcquire.select_routes(routes, statuses: ["direct"])

    assert_equal 25, selected.size
    assert_equal 19, selected.count { |route| route.requirement == "required" }
    assert_equal 6, selected.count { |route| route.requirement == "optional" }
    assert(selected.all? { |route| route.route == "direct-url" })
  end

  test "registry detects missing links and duplicate path ownership" do
    object = object_manifest("object-one")
    @store.write_object(object)

    assert_raises(ArgumentError) { @store.rebuild_registry! }

    object["slot_ids"] = []
    object["slot_manifests"] = []
    @store.write_object(object)
    @store.write_object(object_manifest("object-two"))
    assert_raises(ArgumentError) { @store.rebuild_registry! }
  end

  test "homepage and Wayback routes acquire verified remote content" do
    {"downloadable" => "live-url", "wayback" => "wayback"}.each do |status, route_name|
      url = "https://example.test/#{status}"
      fetcher = FakeAttachmentFetcher.new(PDF_SOURCE)
      store = ZoteroAcquisition::Store.new(File.join(@directory, status))
      FileUtils.mkdir_p(store.root)
      runner = ZoteroAcquisition::Runner.new(store, remote_fetcher: fetcher)
      route = terminal_route("EP-019/software/site", status, "required", route: route_name)
      route.evidence_url = url
      route.source_url = url
      route.item_title = PDF_TITLE
      route.expectations = {"title" => PDF_TITLE}

      result = runner.process(route)

      assert_equal "acquired", result.terminal_status
      assert_equal [url], fetcher.calls
      assert_equal "application/pdf", store.read_object(result.object_id).fetch("media_type")
    end
  end

  test "status filters select the remaining remote inventories" do
    routes = ZoteroAcquire.routes(
      sheet: ZoteroInventoryAudit::SHEET,
      snapshot: ZoteroInventoryAudit::SNAPSHOT,
      csv: ZoteroInventoryAudit::OUT_CSV,
      overrides: ZoteroInventoryAudit::OVERRIDES
    )

    assert_equal 3, ZoteroAcquire.select_routes(routes, statuses: ["clonable"]).size
    assert_equal 19, ZoteroAcquire.select_routes(routes, statuses: ["downloadable"]).size
    assert_equal 12, ZoteroAcquire.select_routes(routes, statuses: ["wayback"]).size
  end

  test "Git acquisition persists a verified repository and resumes without cloning" do
    source = create_repository
    url = "https://example.test/repo.git"
    fetcher = FakeGitFetcher.new(source)
    runner = ZoteroAcquisition::Runner.new(@store, git_fetcher: fetcher)
    route = terminal_route("EP-019/software/repo", "clonable", "required", route: "git-host")
    route.evidence_url = url
    route.source_url = url

    result = runner.process(route)
    resumed = runner.process(route)
    runner.finalize([route])

    assert_equal "acquired", result.terminal_status
    assert_equal "skipped", resumed.action
    assert_equal [url], fetcher.calls
    object = @store.read_object(result.object_id)
    assert_equal "repository", object.fetch("kind")
    assert_equal url, object.fetch("remote_url")
    assert_equal 0, object.dig("clone_status", "exit_status")
    assert_equal git(source, "rev-parse", "HEAD"), object.fetch("head")
    refute_equal source, object.fetch("path")
  end

  test "repository verification accepts a clean repository" do
    path = create_repository
    head = git(path, "rev-parse", "HEAD")

    result = repository_verifier.verify(path, "remote_url" => "https://example.test/repo.git", "head" => head)

    assert_equal "passed", result.fetch("status")
    assert_equal head, result.fetch("head")
    assert_equal false, result.fetch("shallow")
    assert_equal true, result.fetch("worktree_clean")
    assert_equal "passed", result.dig("fsck", "status")
    assert_equal [], result.fetch("submodules")
  end

  test "repository edits and HEAD changes prevent resumption" do
    path = create_repository
    object = repository_object(path)
    @store.write_object(object)
    slot = acquired_slot_for(object)
    @store.write_slot(slot)

    assert @runner.resumable?(slot)
    File.write(File.join(path, "README.md"), "edited")
    refute @runner.resumable?(slot)

    git(path, "checkout", "--", "README.md")
    File.write(File.join(path, "README.md"), "new commit")
    git(path, "add", "README.md")
    git(path, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "Advance HEAD")
    refute @runner.resumable?(slot)
  end

  test "signed URLs are redacted without removing ordinary query parameters" do
    sanitized = ZoteroAcquisition::HttpDownloader.sanitize_url(
      "https://files.example.test/object?part=1&X-Amz-Signature=secret&X-Amz-Credential=credential&token=token"
    )

    assert_includes sanitized, "part=1"
    refute_includes sanitized, "secret"
    refute_includes sanitized, "credential"
    refute_includes sanitized, "token=token"
  end

  private

  def file_verifier
    ZoteroAcquisition::FileVerifier.new
  end

  def repository_verifier
    ZoteroAcquisition::RepositoryVerifier.new
  end

  def directory_verifier
    ZoteroAcquisition::DirectoryVerifier.new
  end

  def create_directory
    path = File.join(@directory, "directory")
    Dir.mkdir(path)
    File.write(File.join(path, "a.txt"), "alpha")
    File.write(File.join(path, "b.lisp"), "(setf *version* \"beta\")")
    expected = %w[a.txt b.lisp].to_h do |name|
      [name, Digest::SHA256.file(File.join(path, name)).hexdigest]
    end
    [path, {"files" => expected, "content_markers" => {"a.txt" => ["alpha"]}, "software_version" => "beta"}]
  end

  def directory_object(path, expectations)
    ZoteroAcquisition::Manifest.object(
      object_id: "directory-one",
      kind: "directory",
      path: path,
      identities: ["local:#{path}"],
      expectations: expectations,
      verification: directory_verifier.verify(path, expectations)
    )
  end

  def pdf_expectations
    {"media_type" => "application/pdf", "title" => PDF_TITLE}
  end

  def local_route(id)
    ZoteroAcquisition::Route.new(
      artifact_id: id,
      audit_unit: id.split("/").first,
      requirement: "required",
      status: "present",
      route: "local-file",
      evidence_url: @pdf,
      evidence: "offline local fixture",
      item_title: PDF_TITLE,
      expectations: pdf_expectations
    )
  end

  def attachment_route(id)
    ZoteroAcquisition::Route.new(
      artifact_id: id,
      audit_unit: id.split("/").first,
      requirement: "required",
      status: "present",
      route: "zotero-stored-pdf",
      evidence_url: "https://aclanthology.org/2021.naacl-main.199.pdf",
      evidence: "offline stored-attachment fixture",
      attachment_key: "CHH5MUHB",
      item_title: PDF_TITLE,
      expectations: pdf_expectations
    )
  end

  def remote_route(id, url:, expectations: pdf_expectations)
    ZoteroAcquisition::Route.new(
      artifact_id: id,
      audit_unit: id.split("/").first,
      requirement: "required",
      status: "oa-resolvable",
      route: "openalex-best-oa",
      evidence_url: url,
      source_url: url,
      evidence: "offline OpenAlex fixture",
      item_title: PDF_TITLE,
      expectations: expectations
    )
  end

  def terminal_route(id, status, requirement, route: status)
    ZoteroAcquisition::Route.new(
      artifact_id: id,
      audit_unit: id.split("/").first,
      requirement: requirement,
      status: status,
      route: route,
      evidence_url: "https://example.test/evidence",
      evidence: "documented test outcome",
      item_title: "Test artifact"
    )
  end

  def slot_manifest(status, object_id: (status == "acquired") ? "object-one" : nil, evidence: "documented evidence")
    ZoteroAcquisition::Manifest.slot(
      artifact_id: "EP-999/paper/main",
      audit_unit: "EP-999",
      requirement: "required",
      route: "test",
      terminal_status: status,
      object_id: object_id,
      verification: {"status" => (status == "acquired") ? "passed" : "recorded", "evidence" => evidence},
      fetched_at: "2026-10-26T00:00:00Z"
    )
  end

  def object_manifest(id)
    verification = file_verifier.verify(@pdf, pdf_expectations)
    ZoteroAcquisition::Manifest.object(
      object_id: id,
      kind: "file",
      path: @pdf,
      identities: ["test:#{id}"],
      media_type: "application/pdf",
      expectations: pdf_expectations,
      verification: verification,
      slot_ids: ["EP-999/paper/main"],
      slot_manifests: ["slots/EP-999/paper/main/manifest.json"]
    )
  end

  def repository_object(path)
    head = git(path, "rev-parse", "HEAD")
    expectations = {"remote_url" => "https://example.test/repo.git", "head" => head}
    verification = repository_verifier.verify(path, expectations)
    ZoteroAcquisition::Manifest.object(
      object_id: "repository-one",
      kind: "repository",
      path: path,
      identities: ["git:https://example.test/repo.git"],
      expectations: expectations,
      verification: verification,
      clone_status: {"exit_status" => 0}
    )
  end

  def acquired_slot_for(object)
    ZoteroAcquisition::Manifest.slot(
      artifact_id: "EP-999/software/repo",
      audit_unit: "EP-999",
      requirement: "required",
      route: "git-host",
      terminal_status: "acquired",
      object_id: object.fetch("object_id"),
      verification: {"status" => "passed", "evidence" => "repository verified"}
    )
  end

  def create_repository
    path = File.join(@directory, "repository")
    Dir.mkdir(path)
    git(path, "init")
    File.write(File.join(path, "README.md"), "initial")
    git(path, "add", "README.md")
    git(path, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "Initial")
    git(path, "remote", "add", "origin", "https://example.test/repo.git")
    path
  end

  def git(path, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", path, *arguments)
    raise "git #{arguments.join(" ")} failed: #{stdout}#{stderr}" unless status.success?
    stdout.strip
  end
end
