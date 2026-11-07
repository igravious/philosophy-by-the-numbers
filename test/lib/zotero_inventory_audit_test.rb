require "test_helper"
require "csv"
require_relative "../../scripts/zotero_inventory_audit"

class ZoteroInventoryAuditTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:responses, :requests) do
    def request(method, url)
      self.requests ||= []
      requests << [method, url]
      response = responses.fetch(url)
      response = response.shift if response.is_a?(Array)
      response || raise("no fake response for #{url}")
    end
  end

  setup do
    @snapshot = ZoteroInventoryAudit::Snapshot.new(ZoteroInventoryAudit::SNAPSHOT)
    @client = FakeClient.new({}, [])
    @classifier = ZoteroInventoryAudit::Classifier.new(@snapshot, client: @client, network: false)
  end

  test "real inventory is complete and confirmed" do
    artifacts = ZoteroInventoryAudit::Inventory.new(ZoteroInventoryAudit::SHEET, @snapshot).artifacts

    assert_equal 140, artifacts.map(&:unit_id).uniq.size
    assert_equal 194, artifacts.size
    assert_equal 172, artifacts.count { |artifact| artifact.requirement == "required" }
    assert_equal 22, artifacts.count { |artifact| artifact.requirement == "optional" }
    assert artifacts.none?(&:proposed)
    assert_equal artifacts.map(&:id).uniq, artifacts.map(&:id)
  end

  test "stored PDF requires an attachment on the artifact item" do
    present = classify("EP-015/paper/main")
    dataset = classify("EP-016/dataset/main")

    assert_equal "present", present.status
    assert_equal "J6H9RTZE", present.attachment_key
    assert_equal "DGWBG5LH", present.item_key
    refute_equal "present", dataset.status
    assert_empty dataset.item_key.to_s
  end

  test "DOI uses best OpenAlex OA evidence" do
    doi = "10.1234/example"
    item = item("PAPER001", "journalArticle", "DOI" => doi)
    url = "https://api.openalex.org/works/doi:#{doi}"
    @client.responses[url] = response(200, body: JSON.generate(
      "id" => "https://openalex.org/W1",
      "is_oa" => true,
      "best_oa_location" => {"landing_page_url" => "https://repository.example/paper", "pdf_url" => "https://repository.example/paper.pdf"}
    ))
    classifier = network_classifier

    result = classifier.classify(artifact("EP-999/paper/main", item))

    assert_equal "oa-resolvable", result.status
    assert_equal "openalex-best-oa", result.route
    assert_equal "https://repository.example/paper.pdf", result.evidence_url
    assert_includes result.evidence, "W1"
  end

  test "current OpenAlex schema uses nested OA flag and best location" do
    item = item("PAPER001", "journalArticle", "DOI" => "10.1234/example")
    url = "https://api.openalex.org/works/doi:10.1234/example"
    @client.responses[url] = response(200, body: JSON.generate(
      "id" => "https://openalex.org/W2",
      "open_access" => {"is_oa" => true},
      "best_oa_location" => {"is_oa" => true, "pdf_url" => "https://publisher.example/paper.pdf"}
    ))

    result = network_classifier.classify(artifact("EP-999/paper/main", item))

    assert_equal "oa-resolvable", result.status
    assert_equal "https://publisher.example/paper.pdf", result.evidence_url
  end

  test "OpenAlex response without an OA indicator is unresolved" do
    item = item("PAPER001", "journalArticle", "DOI" => "10.1234/example")
    url = "https://api.openalex.org/works/doi:10.1234/example"
    @client.responses[url] = response(200, body: JSON.generate("id" => "https://openalex.org/W2"))

    result = network_classifier.classify(artifact("EP-999/paper/main", item))

    assert_equal "unresolved", result.status
    assert_includes result.evidence, "OA indicator"
  end

  test "DOI without OA is manual and OpenAlex failure is unresolved" do
    item = item("PAPER001", "journalArticle", "DOI" => "10.1234/example")
    url = "https://api.openalex.org/works/doi:10.1234/example"
    @client.responses[url] = response(200, body: JSON.generate("id" => "https://openalex.org/W1", "is_oa" => false))
    result = network_classifier.classify(artifact("EP-999/paper/main", item))
    assert_equal "manual", result.status
    assert_includes result.evidence, "no OA"

    @client.responses[url] = response(503, error: "HTTP 503")
    result = network_classifier.classify(artifact("EP-999/paper/main", item))
    assert_equal "unresolved", result.status
    assert_includes result.evidence, "503"
  end

  test "direct full text route requires successful liveness" do
    item = item("PAPER001", "conferencePaper", "url" => "https://aclanthology.org/2021.naacl-main.199")
    @client.responses[item["data"]["url"]] = response(200)
    result = network_classifier.classify(artifact("EP-999/paper/main", item))

    assert_equal "direct", result.status
    assert_equal "direct-url", result.route
    assert_equal item["data"]["url"], result.evidence_url
  end

  test "git repository and reference artifact use their own live URLs" do
    repo = artifact("EP-999/software/repo", nil, basis: "https://github.com/example/project", evidence: "explicit repository")
    reference = artifact("EP-999/dataset/main", nil, basis: "dataset documented at https://example.test/data", evidence: "dataset documentation")
    @client.responses["https://github.com/example/project"] = response(200)
    @client.responses["https://example.test/data"] = response(200)

    assert_equal "clonable", network_classifier.classify(repo).status
    assert_equal "reference-only", network_classifier.classify(reference).status
    assert_equal "https://example.test/data", network_classifier.classify(reference).evidence_url
  end

  test "dead software link uses Wayback but transient failure stays unresolved" do
    dead = artifact("EP-999/software/site", item("SOFT0001", "computerProgram", "url" => "http://gone.test/app"))
    wayback = "https://archive.org/wayback/available?url=http%3A%2F%2Fgone.test%2Fapp"
    @client.responses[dead.source_url] = response(404)
    @client.responses[wayback] = response(200, body: JSON.generate(
      "archived_snapshots" => {"closest" => {"url" => "https://web.archive.org/web/20200101000000/http://gone.test/app", "timestamp" => "20200101000000"}}
    ))
    result = network_classifier.classify(dead)
    assert_equal "wayback", result.status
    assert_equal "https://web.archive.org/web/20200101000000/http://gone.test/app", result.evidence_url

    transient = artifact("EP-999/software/site", item("SOFT0002", "computerProgram", "url" => "http://slow.test/app"))
    @client.responses[transient.source_url] = response(nil, error: "connection timed out")
    @client.responses["https://archive.org/wayback/available?url=http%3A%2F%2Fslow.test%2Fapp"] = response(200, body: JSON.generate("archived_snapshots" => {}))
    result = network_classifier.classify(transient)
    assert_equal "unresolved", result.status
    refute_equal "lost-candidate", result.status
  end

  test "keyless text artifact without a route is unresolved" do
    result = network_classifier.classify(artifact("EP-999/document/manual", nil))

    assert_equal "unresolved", result.status
    assert_equal "no-route", result.route
    assert result.review_needed
  end

  test "book without any retrieval route is unresolved" do
    result = network_classifier.classify(artifact("EP-999/book/main", item("BOOK0001", "book")))

    assert_equal "unresolved", result.status
    assert_equal "no-route", result.route
  end

  test "software without a route is a lost candidate" do
    result = network_classifier.classify(artifact("EP-999/software/site", nil))

    assert_equal "lost-candidate", result.status
    assert_equal "no-route", result.route
    assert result.review_needed
  end

  test "Wayback API failure prevents a loss ruling" do
    dead = artifact("EP-999/software/site", item("SOFT0001", "computerProgram", "url" => "http://gone.test/app"))
    wayback = "https://archive.org/wayback/available?url=http%3A%2F%2Fgone.test%2Fapp"
    @client.responses[dead.source_url] = response(404)
    @client.responses[wayback] = response(503, error: "HTTP 503")

    result = network_classifier.classify(dead)

    assert_equal "unresolved", result.status
    assert_includes result.evidence, "Wayback"
    assert_includes result.evidence, "503"
  end

  test "documented originals are lost candidates without network inference" do
    %w[EP-004/software/original EP-006/software/original].each do |id|
      result = classify(id)
      assert_equal "lost-candidate", result.status
      assert_equal "documented-unlocated", result.route
      assert result.review_needed
      refute_empty result.evidence
    end
    assert_empty @client.requests.to_a
  end

  test "HTTP client follows HEAD redirects and bounds dead-link retries" do
    client = ZoteroInventoryAudit::HttpClient.new(delay: 0, sleeper: ->(_) {})
    calls = []
    responses = {
      "http://example.test/start" => response(302),
      "http://example.test/next" => response(200)
    }
    responses["http://example.test/start"].location = "/next"
    responses["http://example.test/next"].url = "http://example.test/next"
    client.define_singleton_method(:perform) do |method, url, _attempts|
      calls << [method, url]
      responses.fetch(url)
    end

    result = client.request("HEAD", "http://example.test/start")

    assert result.success?
    assert_equal "http://example.test/next", result.url
    assert_equal [["HEAD", "http://example.test/start"], ["HEAD", "http://example.test/next"]], calls

    dead_client = ZoteroInventoryAudit::HttpClient.new(delay: 0, sleeper: ->(_) {})
    dead_calls = 0
    dead_client.define_singleton_method(:perform) do |_method, url, attempts|
      dead_calls += 1
      ZoteroInventoryAudit::Response.new(status: 404, url: url, body: "", attempts: attempts)
    end
    assert_equal 404, dead_client.request("HEAD", "http://gone.test/app").status
    assert_equal 2, dead_calls
  end

  test "CSV and review document preserve every row and review distinction" do
    rows = %w[EP-004/software/original EP-006/software/original EP-015/paper/main].map { |id| classify(id) }
    Dir.mktmpdir do |directory|
      csv_path = File.join(directory, "audit.csv")
      markdown_path = File.join(directory, "audit.md")
      ZoteroInventoryAudit::Writer.new(rows, sheet_path: "sheet.yaml", snapshot_path: "snapshot.json", expected_count: 3).write(csv_path, markdown_path)
      csv = CSV.read(csv_path, headers: true)
      markdown = File.read(markdown_path)

      assert_equal 3, csv.size
      assert(csv.all? { |row| !row["evidence"].to_s.empty? })
      assert_includes markdown, "Review needed"
      assert_includes markdown, "`manual`"
      assert_includes markdown, "`unresolved`"
      assert_includes markdown, "`lost-candidate`"
    end
  end

  test "curated local overrides and resumed CSV preserve evidence" do
    artifact = ZoteroInventoryAudit::Inventory.new(ZoteroInventoryAudit::SHEET, @snapshot).artifacts.find { |entry| entry.id == "EP-001/paper/main" }
    result = @classifier.classify(artifact)
    Dir.mktmpdir do |directory|
      override_path = File.join(directory, "overrides.yaml")
      local_path = "sources/emerging_philosophy/scans/philosophy-and-the-computer-1992/chapters/ch12-croy-amidon-graphic-mouse-driven-interface_pp213-217.pdf"
      File.write(override_path, YAML.dump({
        "EP-001/paper/main" => {
          "status" => "present", "route" => "local-file", "confidence" => "high",
          "evidence_url" => local_path, "evidence" => "complete local chapter", "review_needed" => false
        }
      }))
      overridden = ZoteroInventoryAudit.apply_overrides([result], override_path).first
      assert_equal "present", overridden.status
      assert_equal local_path, overridden.evidence_url
      ZoteroInventoryAudit::Writer.new([overridden], sheet_path: "sheet.yaml", snapshot_path: "snapshot.json", expected_count: 1)

      csv_path = File.join(directory, "resume.csv")
      CSV.open(csv_path, "w") do |csv|
        csv << %w[artifact_id status route confidence attachment_key evidence_url evidence review_needed]
        csv << ["EP-001/paper/main", "unresolved", "no-route", "low", "", "", "base evidence", true]
      end
      resumed = ZoteroInventoryAudit.resume_results(csv_path, [artifact]).first
      assert_equal "base evidence", resumed.evidence
      assert_equal "unresolved", resumed.status
      assert resumed.review_needed
    end
  end

  private

  def classify(id)
    artifact = ZoteroInventoryAudit::Inventory.new(ZoteroInventoryAudit::SHEET, @snapshot).artifacts.find { |entry| entry.id == id }
    @classifier.classify(artifact)
  end

  def network_classifier
    ZoteroInventoryAudit::Classifier.new(@snapshot, client: @client, network: true)
  end

  def response(status, body: "", error: nil)
    ZoteroInventoryAudit::Response.new(status: status, url: "", body: body, error: error, attempts: 1)
  end

  def item(key, type, extra = {})
    {"key" => key, "data" => {"key" => key, "itemType" => type, "title" => "Title #{key}"}.merge(extra)}
  end

  def artifact(id, item, basis: nil, evidence: "test evidence")
    ZoteroInventoryAudit::Artifact.new(
      id: id,
      unit_id: id.split("/").first,
      unit_name: "Test unit",
      requirement: "required",
      proposed: false,
      basis: basis || (item && "#{item["data"]["itemType"]} #{item["key"]}") || "no item",
      inventory_evidence: evidence,
      item: item
    )
  end
end
