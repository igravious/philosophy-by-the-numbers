require "test_helper"
require "tmpdir"
require "open3"
require "yaml"
require "json"

class ZoteroPhase2RemediationTest < ActiveSupport::TestCase
  ROOT = File.expand_path("../..", __dir__)
  SOURCE = File.join(ROOT, "sources/emerging_philosophy")
  GENERATOR = File.join(ROOT, "scripts/zotero_cluster.rb")
  VERIFIER = File.join(ROOT, "scripts/zotero_verify_decisions.rb")

  setup do
    @directory = Dir.mktmpdir
    @ledger = prepare_copy("decisions.jsonl")
    @registry = prepare_copy("singleton-ids.json")
    @idmap = prepare_copy("regen-idmap.json")
    @yaml = prepare_copy("review-sheet-v2.yaml")
    @markdown = prepare_copy("review-sheet-v2.md")
    @identity = prepare_copy("review-sheet-v2.yaml", "identity.yaml")
    @baseline = prepare_copy("review-sheet-v2.yaml", "baseline.yaml")
    proposal_ledger = File.readlines(@ledger).reject { |line| JSON.parse(line)["type"] == "inventory" }
    File.write(@ledger, proposal_ledger.join)
    raise @command_output unless generate.success?
    FileUtils.cp(@yaml, @baseline)
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "inventory confirmations and removals survive repeated regeneration" do
    append_ledger({"type" => "inventory", "id" => "EP-028/software/repo", "requirement" => "optional", "note" => "test confirmation"})
    append_ledger({"type" => "inventory", "id" => "EP-028/book/main", "requirement" => "not-expected", "note" => "test removal"})
    append_ledger({"type" => "inventory", "id" => "EP-028/document/supplement", "requirement" => "optional", "basis" => "test new artifact"})

    2.times do
      assert generate.success?, @command_output
      row = sheet.fetch("singletons").find { |entry| entry.fetch("id") == "EP-028" }
      inventory = row.fetch("inventory")
      software = inventory.find { |entry| entry.fetch("id") == "EP-028/software/repo" }
      assert_equal "optional", software.fetch("requirement")
      assert_equal false, software.fetch("proposed")
      assert_equal "test confirmation", software.fetch("note")
      assert_nil inventory.find { |entry| entry.fetch("id") == "EP-028/book/main" }
      addition = inventory.find { |entry| entry.fetch("id") == "EP-028/document/supplement" }
      assert_equal "test new artifact", addition.fetch("basis")
      assert_equal false, addition.fetch("proposed")
    end
    assert verify("ZOTERO_PRESERVATION_BASELINE" => @baseline).success?, @command_output

    document = sheet
    row = document.fetch("singletons").find { |entry| entry.fetch("id") == "EP-028" }
    row.fetch("inventory") << {"id" => "EP-028/paper/unauthorized", "requirement" => "optional", "proposed" => true, "basis" => "test drift"}
    File.write(@yaml, document.to_yaml)
    refute verify("ZOTERO_PRESERVATION_BASELINE" => @baseline).success?, "one ruling masked another inventory change"
  end

  test "singleton survives anchoring and return with the same EP ID" do
    append_ledger({"type" => "project", "key" => "2PIU8IIM", "name" => "Computer Revolution in Philosophy"})

    assert generate.success?, @command_output
    anchored = sheet.fetch("proposed_clusters").find { |unit| unit.fetch("members").first.fetch("key") == "2PIU8IIM" }
    assert_equal "EP-028", anchored.fetch("id")
    assert_equal "singleton", anchored.fetch("grouping")
    assert_equal 112, sheet.dig("statistics", "unanchored_singletons")
    assert_equal 17, sheet.dig("statistics", "anchored_singletons")
    assert verify.success?, @command_output

    File.write(@ledger, File.read(File.join(SOURCE, "decisions.jsonl")))
    assert generate.success?, "return generation failed"
    returned = sheet.fetch("singletons").find { |entry| entry.fetch("key") == "2PIU8IIM" }
    assert_equal "EP-028", returned.fetch("id")
    assert_equal 113, sheet.dig("statistics", "unanchored_singletons")
    assert verify.success?, @command_output
  end

  test "failed generation leaves every output unchanged" do
    File.write(@registry, JSON.generate([
      {"key" => "2PIU8IIM", "id" => "EP-028"},
      {"key" => "PTDUCCRS", "id" => "EP-028"}
    ]))
    sentinels = {@yaml => "yaml sentinel", @markdown => "markdown sentinel", @registry => "registry sentinel", @idmap => "idmap sentinel"}
    sentinels.each { |path, content| File.write(path, content) }

    refute generate.success?, "invalid registry unexpectedly succeeded"
    sentinels.each { |path, content| assert_equal content, File.read(path), "#{path} changed after failure" }
  end

  test "verifier resolves EP targets and validates inventory structure" do
    document = sheet
    link = document.fetch("proposed_clusters").first.fetch("candidate_links").first
    link["to_project"] = "EP-999"
    File.write(@yaml, document.to_yaml)
    refute verify.success?, "nonexistent EP target passed verification"

    document = sheet
    row = document.fetch("singletons").first
    row["inventory"].first["proposed"] = "true"
    File.write(@yaml, document.to_yaml)
    refute verify.success?, "invalid inventory structure passed verification"
  end

  test "empty inventory is valid but optional preservation checking detects drift" do
    document = sheet
    row = document.fetch("singletons").first
    row["inventory"] = []
    row["needs_you"] = []
    File.write(@yaml, document.to_yaml)

    assert verify.success?, "empty inventory should be structurally valid"
    refute verify("ZOTERO_PRESERVATION_BASELINE" => @baseline).success?, "inventory drift passed preservation verification"
  end

  test "verifier compares population keys to the frozen snapshot" do
    document = sheet
    document.fetch("singletons").first["key"] = "NOT_A_SNAPSHOT_KEY"
    File.write(@yaml, document.to_yaml)

    refute verify.success?, "unknown population key passed verification"
  end

  private

  def prepare_copy(filename, destination = nil)
    path = File.join(@directory, destination || filename)
    FileUtils.cp(File.join(SOURCE, filename), path)
    path
  end

  def append_ledger(record)
    File.open(@ledger, "a") { |file| file.puts(JSON.generate(record)) }
  end

  def sheet
    YAML.load_file(@yaml)
  end

  def generator_environment
    {
      "ZOTERO_SHEET_YAML" => @yaml,
      "ZOTERO_SHEET_MD" => @markdown,
      "ZOTERO_SINGLETON_IDS" => @registry,
      "ZOTERO_DECISIONS" => @ledger,
      "ZOTERO_IDMAP" => @idmap,
      "ZOTERO_IDENTITY_SHEET" => @identity
    }
  end

  def generate
    run_script(GENERATOR)
  end

  def verify(extra_environment = {})
    run_script(VERIFIER, {"ZOTERO_PRESERVATION_BASELINE" => nil}.merge(extra_environment))
  end

  def run_script(script, extra_environment = {})
    command = [File.join(ROOT, "bin/bundle"), "exec", "ruby"]
    command << File.join(ROOT, "test/support/subprocess_coverage.rb") if ENV["COVERAGE"]
    command << script
    stdout, stderr, status = Open3.capture3(generator_environment.merge(extra_environment), *command, chdir: ROOT)
    @command_output = stdout + stderr
    status
  end
end
