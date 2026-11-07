#!/usr/bin/env ruby

require "csv"
require "digest"
require "json"
require "net/http"
require "optparse"
require "tempfile"
require "time"
require "uri"
require "yaml"

module ZoteroInventoryAudit
  ROOT = File.expand_path("..", __dir__)
  SHEET = ENV.fetch("ZOTERO_AUDIT_SHEET", File.join(ROOT, "sources/emerging_philosophy/review-sheet-v2.yaml"))
  SNAPSHOT = ENV.fetch("ZOTERO_AUDIT_SNAPSHOT", File.join(ROOT, "sources/emerging_philosophy/dumps/snapshot-20261015T172014Z.json"))
  OUT_CSV = ENV.fetch("ZOTERO_AUDIT_CSV", File.join(ROOT, "sources/emerging_philosophy/artifact-audit-2026-10-26.csv"))
  OUT_MD = ENV.fetch("ZOTERO_AUDIT_MD", File.join(ROOT, "docs/ep/phase-2-source-material-audit-for-review-2026-10-26.md"))
  OVERRIDES = ENV.fetch("ZOTERO_AUDIT_OVERRIDES", File.join(ROOT, "sources/emerging_philosophy/artifact-audit-overrides-2026-10-26.yaml"))
  USER_AGENT = "CorpusBuilderPhase2SourceAudit/1.0 (metadata and liveness only; no artifact downloads)"
  TEXT_KINDS = %w[paper book thesis document].freeze
  REFERENCE_KINDS = %w[web video dataset visualization issue].freeze
  GIT_HOSTS = %w[github.com gitlab.com bitbucket.org sourceforge.net].freeze
  PAYWALLED_HOSTS = %w[
    jstor.org degruyter.com link.springer.com springer.com onlinelibrary.wiley.com wiley.com
    academic.oup.com cambridge.org bloomsburycollections.com ieeexplore.ieee.org portal.acm.org
    doi.acm.org dl.acm.org linkinghub.elsevier.com philpapers.org researchgate.net mitpress.mit.edu
    blackwells.co.uk
  ].freeze

  Response = Struct.new(:status, :url, :body, :error, :attempts, :location, keyword_init: true) do
    def success?
      status.to_i.between?(200, 399) && error.nil?
    end

    def definitive_death?
      [404, 410].include?(status.to_i)
    end

    def summary
      return "HTTP #{status} after #{attempts} attempt#{"s" unless attempts == 1}" if status
      "#{error || "request failed"} after #{attempts} attempt#{"s" unless attempts == 1}"
    end
  end

  class HttpClient
    attr_reader :requests

    def initialize(timeout: 10, retries: 2, delay: 0.2, sleeper: Kernel.method(:sleep))
      @timeout = timeout
      @retries = retries
      @delay = delay
      @sleeper = sleeper
      @cache = {}
      @requests = []
      @last_request = nil
    end

    def request(method, url)
      key = [method.to_s.upcase, url]
      return @cache[key] if @cache.key?(key)

      response = request_with_redirects(method.to_s.upcase, url)
      @cache[key] = response
    end

    private

    def request_with_redirects(method, url, redirects = 0)
      return Response.new(url: url, body: "", error: "too many redirects", attempts: 0) if redirects > 5

      response = request_with_retries(method, url)
      location = response.location
      if response.status.to_i.between?(300, 399) && location
        target = URI.join(url, location).to_s
        followed = request_with_redirects(method, target, redirects + 1)
        return Response.new(status: followed.status, url: followed.url, body: followed.body,
          error: followed.error, attempts: response.attempts.to_i + followed.attempts.to_i)
      end
      response
    rescue URI::InvalidURIError => e
      Response.new(url: url, body: "", error: "invalid redirect: #{e.message}", attempts: response.attempts)
    end

    def request_with_retries(method, url)
      attempts = 0
      loop do
        attempts += 1
        response = perform(method, url, attempts)
        return response if response.success?
        return response unless retryable?(response)
        return response if attempts > dead_limit(response)

        @sleeper.call(0.5 * (2**(attempts - 1)))
      end
    end

    def dead_limit(response)
      response.definitive_death? ? 1 : @retries
    end

    def retryable?(response)
      response.error || response.definitive_death? || response.status.to_i == 429 || response.status.to_i >= 500
    end

    def perform(method, url, attempts)
      throttle
      uri = URI.parse(url)
      raise URI::InvalidURIError, "only HTTP(S) URLs are supported" unless uri.is_a?(URI::HTTP) && uri.host

      response = nil
      @requests << {method: method, url: url, at: Time.now.utc.iso8601}
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
        open_timeout: @timeout, read_timeout: @timeout, write_timeout: @timeout) do |http|
        request = (method == "HEAD") ? Net::HTTP::Head.new(uri) : Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "application/json" if method == "GET"
        response = http.request(request)
      end
      Response.new(status: response.code.to_i, url: url, body: response.body.to_s,
        location: response["location"], attempts: attempts)
    rescue => e
      Response.new(url: url, body: "", error: "#{e.class}: #{e.message}", attempts: attempts)
    end

    def throttle
      return unless @last_request

      remaining = @delay - (Time.now - @last_request)
      @sleeper.call(remaining) if remaining.positive?
    ensure
      @last_request = Time.now
    end
  end

  class Response
    attr_accessor :location
  end

  class Snapshot
    attr_reader :items, :by_key

    def initialize(path)
      document = JSON.parse(File.read(path))
      @items = document.fetch("items")
      @by_key = @items.to_h { |item| [item.fetch("key"), item] }
      raise "duplicate snapshot item keys" unless @by_key.size == @items.size
      raise "snapshot top-level count mismatch" unless top_level.size == document.dig("metadata", "counts", "top_level")

      orphans = document.dig("metadata", "verification", "child_parent_integrity", "orphans")
      if orphans && (orphans["standalone_count"] + orphans["broken_ref_count"]) != 0
        raise "snapshot contains orphaned records"
      end
    end

    def top_level
      @items.reject { |item| %w[attachment note].include?(item.dig("data", "itemType")) }
    end

    def pdf_attachments(parent_key)
      @items.select do |item|
        data = item["data"]
        data["itemType"] == "attachment" && data["parentItem"] == parent_key &&
          data["contentType"] == "application/pdf" && %w[imported_file imported_url].include?(data["linkMode"])
      end.sort_by { |item| item["key"] }
    end
  end

  Artifact = Struct.new(:id, :unit_id, :unit_name, :requirement, :proposed, :basis,
    :inventory_evidence, :item, keyword_init: true) do
    def kind
      id.split("/")[1]
    end

    def item_key
      item && item["key"]
    end

    def item_title
      item&.dig("data", "title")
    end

    def item_type
      item&.dig("data", "itemType")
    end

    def doi
      item ? item.dig("data", "DOI").to_s.strip : ""
    end

    def source_url
      return item.dig("data", "url").to_s.strip if item && !item.dig("data", "url").to_s.strip.empty?

      text = "#{basis}\n#{inventory_evidence}"
      url = text[%r{https?://[^\s<>`"']+}, 0]
      return url.gsub(/[].,;)}]+\z/, "") if url

      bare = text[%r{(?:github|gitlab)\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+}, 0]
      bare && "https://#{bare}"
    end
  end

  class Inventory
    attr_reader :artifacts

    def initialize(sheet_path, snapshot, snapshot_path: ZoteroInventoryAudit::SNAPSHOT)
      @snapshot_path = snapshot_path
      sheet = YAML.load_file(sheet_path)
      units = sheet.fetch("proposed_clusters") + sheet.fetch("singletons")
      @artifacts = units.flat_map do |unit|
        unit.fetch("inventory").map do |entry|
          Artifact.new(id: entry.fetch("id"), unit_id: unit.fetch("id"),
            unit_name: unit["proposed_name"] || unit["title"], requirement: entry.fetch("requirement"),
            proposed: entry.fetch("proposed"), basis: entry["basis"].to_s,
            inventory_evidence: entry["evidence"].to_s, item: resolve_item(entry, snapshot))
        end
      end
      validate!(sheet, sheet_path, snapshot)
    end

    private

    def resolve_item(entry, snapshot)
      key = snapshot_key(entry["basis"].to_s, snapshot)
      key ||= snapshot_key(entry["evidence"].to_s, snapshot) if entry["id"].split("/")[1] == "paper"
      key && snapshot.by_key.fetch(key)
    end

    def snapshot_key(text, snapshot)
      text.scan(/\b[A-Z0-9]{8}\b/).find { |key| snapshot.by_key.key?(key) }
    end

    def validate!(sheet, sheet_path, snapshot)
      raise "expected 140 audit units, got #{@artifacts.map(&:unit_id).uniq.size}" unless @artifacts.map(&:unit_id).uniq.size == 140
      raise "expected 194 artifacts, got #{@artifacts.size}" unless @artifacts.size == 194
      raise "expected 172 required artifacts" unless @artifacts.count { |a| a.requirement == "required" } == 172
      raise "expected 22 optional artifacts" unless @artifacts.count { |a| a.requirement == "optional" } == 22
      raise "unconfirmed inventory entries present" if @artifacts.any?(&:proposed)
      raise "duplicate artifact IDs" unless @artifacts.map(&:id).uniq.size == @artifacts.size
      return unless sheet.dig("generated_from", "snapshot_sha256")

      actual = Digest::SHA256.file(@snapshot_path).hexdigest
      expected = sheet.dig("generated_from", "snapshot_sha256")
      raise "snapshot SHA256 does not match review sheet" unless actual == expected
    end
  end

  Result = Struct.new(:artifact, :status, :route, :confidence, :attachment_key, :evidence_url,
    :evidence, :review_needed, keyword_init: true) do
    def id
      artifact.id
    end

    def unit_id
      artifact.unit_id
    end

    def requirement
      artifact.requirement
    end

    def kind
      artifact.kind
    end

    def item_key
      artifact.item_key
    end

    def item_title
      artifact.item_title
    end

    def item_type
      artifact.item_type
    end

    def doi
      artifact.doi
    end

    def source_url
      artifact.source_url
    end
  end

  class Classifier
    def initialize(snapshot, client: HttpClient.new, network: true)
      @snapshot = snapshot
      @client = client
      @network = network
    end

    def classify(artifact)
      @artifact = artifact
      return result("lost-candidate", "documented-unlocated", "high", inventory_evidence, true) if documented_original?
      return stored_pdf if stored_pdf?

      case artifact.kind
      when "software"
        classify_software
      when *REFERENCE_KINDS
        classify_reference
      when *TEXT_KINDS
        classify_text
      else
        result("unresolved", "no-route", "low", "No classifier route for artifact kind #{artifact.kind}; #{inventory_evidence}", true)
      end
    end

    private

    def documented_original?
      %w[EP-004/software/original EP-006/software/original].include?(@artifact.id)
    end

    def stored_pdf?
      TEXT_KINDS.include?(@artifact.kind) && @artifact.item_key && !@snapshot.pdf_attachments(@artifact.item_key).empty?
    end

    def stored_pdf
      attachment = @snapshot.pdf_attachments(@artifact.item_key).first
      evidence = "Stored Zotero PDF attachment #{attachment["key"]} on matching item #{@artifact.item_key}; " \
        "filename=#{attachment.dig("data", "filename")}; #{inventory_evidence}"
      result("present", "zotero-stored-pdf", "high", evidence, false,
        attachment_key: attachment["key"])
    end

    def classify_text
      return openalex unless @artifact.doi.empty?
      return direct if direct_url?(@artifact.source_url)
      return manual("Book/publication source has no stored PDF, DOI, or direct full-text route") if @artifact.kind == "book" && @artifact.item && !blank?(@artifact.source_url)
      return manual("Known paywalled/platform source has no stored PDF or direct full-text route") if paywalled?(@artifact.source_url)

      result("unresolved", "no-route", "low", "No stored PDF, DOI, or direct full-text route; #{inventory_evidence}", true)
    end

    def openalex
      url = "https://api.openalex.org/works/doi:#{@artifact.doi}"
      response = request("GET", url)
      return response_failure("openalex", response, "OpenAlex resolution could not be verified") unless response.success?

      work = JSON.parse(response.body)
      locations = [work["best_oa_location"]] + work.fetch("locations", []).select { |location| location["is_oa"] }
      location = locations.compact.find { |entry| entry["pdf_url"] || entry["landing_page_url"] }
      evidence_url = location && (location["pdf_url"] || location["landing_page_url"])
      oa = work.key?("is_oa") ? work["is_oa"] : work.dig("open_access", "is_oa")
      oa = location["is_oa"] if oa.nil? && location
      if oa && evidence_url
        evidence = "OpenAlex #{work["id"]} confirms OA; best OA evidence URL=#{evidence_url}; DOI=#{@artifact.doi}"
        result("oa-resolvable", "openalex-best-oa", "high", evidence, false, evidence_url: evidence_url)
      elsif oa.nil?
        result("unresolved", "openalex", "low", "OpenAlex #{work["id"] || "record"} omitted the OA indicator; no availability ruling made; DOI=#{@artifact.doi}", true,
          evidence_url: work["id"])
      else
        evidence = "OpenAlex #{work["id"] || "record"} reports no OA location (is_oa=#{oa.inspect}); DOI=#{@artifact.doi}; manual retrieval required"
        result("manual", "openalex-no-oa", "high", evidence, true, evidence_url: work["id"])
      end
    rescue JSON::ParserError => e
      result("unresolved", "openalex", "low", "OpenAlex returned invalid JSON: #{e.message}; DOI=#{@artifact.doi}", true, evidence_url: url)
    end

    def direct
      response = request("HEAD", @artifact.source_url)
      return response_failure("direct-url", response, "Direct full-text URL could not be verified") unless response.success?

      result("direct", "direct-url", "high", "Direct full-text pattern verified by HEAD: #{response.summary}; final URL=#{final_url(response)}", false,
        evidence_url: final_url(response))
    end

    def classify_software
      url = @artifact.source_url
      return result("lost-candidate", "no-route", "medium", "No artifact-specific software URL or other retrieval route; #{inventory_evidence}", true) if blank?(url)

      response = request("HEAD", url)
      if response.success?
        if git_host?(url)
          result("clonable", "git-host", "high", "Git repository verified by HEAD: #{response.summary}; final URL=#{final_url(response)}", false,
            evidence_url: final_url(response))
        else
          result("downloadable", "live-url", "high", "Software homepage/download verified by HEAD: #{response.summary}; final URL=#{final_url(response)}", false,
            evidence_url: final_url(response))
        end
      else
        software_failure(response)
      end
    end

    def classify_reference
      url = @artifact.source_url
      return result("unresolved", "no-route", "low", "No artifact-specific reference URL; #{inventory_evidence}", true) if blank?(url)

      response = request("HEAD", url)
      if response.success?
        result("reference-only", "reference-live-url", "high", "Reference URL verified by HEAD: #{response.summary}; final URL=#{final_url(response)}", false,
          evidence_url: final_url(response))
      else
        reference_failure(response)
      end
    end

    def final_url(response)
      response.url.to_s.empty? ? @artifact.source_url : response.url
    end

    def software_failure(response)
      return response_failure("live-url", response, "Software URL failure is not sufficient evidence of loss") unless response.definitive_death? || response.error

      archived, archive_error = wayback(@artifact.source_url)
      if archived
        result("wayback", "wayback", "medium", "Live URL failed (#{response.summary}); Wayback capture=#{archived}", false,
          evidence_url: archived)
      elsif archive_error
        result("unresolved", "wayback", "low", "Live URL failed (#{response.summary}); Wayback check failed (#{archive_error}); loss not inferred", true,
          evidence_url: @artifact.source_url)
      elsif response.definitive_death?
        result("lost-candidate", "no-route", "medium", "Repeated #{response.summary}; Wayback reports no capture; #{inventory_evidence}", true,
          evidence_url: @artifact.source_url)
      else
        response_failure("live-url", response, "Software URL remains unverified after bounded retries and no Wayback capture; loss not inferred")
      end
    end

    def reference_failure(response)
      return response_failure("reference-live-url", response, "Reference URL could not be verified") unless response.definitive_death? || response.error

      archived, archive_error = wayback(@artifact.source_url)
      if archived
        result("reference-only", "wayback-reference", "medium", "Live reference failed (#{response.summary}); Wayback reference=#{archived}", false,
          evidence_url: archived)
      elsif archive_error
        result("unresolved", "wayback", "low", "Live reference failed (#{response.summary}); Wayback check failed (#{archive_error})", true,
          evidence_url: @artifact.source_url)
      else
        response_failure("reference-live-url", response, "No live reference or Wayback capture could be verified")
      end
    end

    def wayback(url)
      endpoint = "https://archive.org/wayback/available?url=#{URI.encode_www_form_component(url)}"
      response = request("GET", endpoint)
      return [nil, response.summary] unless response.success?

      closest = JSON.parse(response.body).dig("archived_snapshots", "closest")
      capture = closest && closest["available"] != false && closest["url"]
      capture ? [capture, nil] : [nil, nil]
    rescue JSON::ParserError => e
      [nil, "invalid JSON: #{e.message}"]
    end

    def response_failure(route, response, prefix)
      result("unresolved", route, "low", "#{prefix}: #{response.summary}; source=#{@artifact.source_url}", true,
        evidence_url: @artifact.source_url)
    end

    def manual(reason)
      result("manual", "manual-retrieval", "high", "#{reason}; DOI=#{@artifact.doi}; source=#{@artifact.source_url}; #{inventory_evidence}", true,
        evidence_url: @artifact.source_url)
    end

    def request(method, url)
      return Response.new(url: url, body: "", error: "network disabled", attempts: 0) unless @network

      @client.request(method, url)
    end

    def result(status, route, confidence, evidence, review_needed, attachment_key: nil, evidence_url: nil)
      Result.new(artifact: @artifact, status: status, route: route, confidence: confidence,
        attachment_key: attachment_key, evidence_url: evidence_url, evidence: evidence,
        review_needed: review_needed)
    end

    def inventory_evidence
      "Inventory evidence: #{@artifact.inventory_evidence}"
    end

    def direct_url?(url)
      return false if blank?(url)

      uri = URI.parse(url)
      host = uri.host.to_s.downcase.sub(/\Awww\./, "")
      path = uri.path.to_s.downcase
      host == "aclanthology.org" || host == "arxiv.org" || path.end_with?(".pdf") ||
        path.include?("/viewfile/") || (host == "dharchive.org" && path.include?("/paper/"))
    rescue URI::InvalidURIError
      false
    end

    def paywalled?(url)
      PAYWALLED_HOSTS.include?(host(url))
    end

    def git_host?(url)
      GIT_HOSTS.include?(host(url))
    end

    def host(url)
      URI.parse(url.to_s).host.to_s.downcase.sub(/\Awww\./, "")
    rescue URI::InvalidURIError
      ""
    end

    def blank?(value)
      value.nil? || value.strip.empty?
    end
  end

  class Writer
    HEADERS = %w[
      artifact_id audit_unit artifact_type requirement proposed status route review_needed confidence
      item_key item_title item_type doi source_url attachment_key evidence_url evidence
    ].freeze

    def initialize(results, sheet_path:, snapshot_path:, network_stats: {}, expected_count: 194)
      @results = results
      @sheet_path = sheet_path
      @snapshot_path = snapshot_path
      @network_stats = network_stats
      @expected_count = expected_count
      validate!
    end

    def write(csv_path, markdown_path)
      content = CSV.generate do |csv|
        csv << HEADERS
        @results.each { |result| csv << row(result) }
      end
      atomic_write(csv_path, content)
      atomic_write(markdown_path, markdown)
    end

    private

    def validate!
      raise "audit must contain exactly #{@expected_count} rows" unless @results.size == @expected_count
      raise "blank evidence in audit" if @results.any? { |result| result.evidence.to_s.strip.empty? }
      raise "stored-PDF row lacks matching attachment key" if @results.any? { |result| result.status == "present" && result.route == "zotero-stored-pdf" && (result.attachment_key.to_s.empty? || result.item_key.to_s.empty?) }
      local_present = @results.select { |result| result.status == "present" && result.route.start_with?("local-") }
      raise "local-present row lacks an existing path" if local_present.any? { |result| result.evidence_url.to_s.empty? || !File.exist?(File.expand_path(result.evidence_url, ROOT)) }
      raise "review flags missing" if @results.any? { |result| %w[manual unresolved lost-candidate].include?(result.status) && !result.review_needed }
    end

    def row(result)
      [result.id, result.unit_id, result.kind, result.requirement, result.artifact.proposed,
        result.status, result.route, result.review_needed, result.confidence, result.item_key,
        result.item_title, result.item_type, result.doi, result.source_url, result.attachment_key,
        result.evidence_url, result.evidence]
    end

    def markdown
      lines = [
        "# Phase 2 source-material audit for review",
        "",
        "Generated: #{Time.now.utc.iso8601}",
        "",
        "Inputs: `#{@sheet_path}` and frozen `#{@snapshot_path}`. The audit contains one row per confirmed inventory artifact; it does not alter inventory requirements, ledger rulings, Zotero, or artifact files.",
        "",
        "Coverage: **#{@results.size} artifacts** (#{@results.count { |r| r.requirement == "required" }} required, #{@results.count { |r| r.requirement == "optional" }} optional), across **#{@results.map(&:unit_id).uniq.size} audit units**.",
        "",
        "**Phase 2 complete (2026-10-26).** The user accepted manual retrieval for seven publications and requested a targeted search of the other eight cases. That search upgraded EP-011 and EP-020; the remaining unresolved and lost-candidate statuses preserve their evidence rather than asserting nonexistence.",
        "",
        "Liveness uses serial HEAD requests with an identifying User-Agent, timeouts, bounded retries/backoff, and redirect limits. OpenAlex and Wayback requests retrieve metadata only; no artifact bytes are downloaded. Unpaywall is not used.",
        "",
        "## Status counts",
        "",
        "| Status | Rows | Review needed |",
        "|---|---:|---:|"
      ]
      counts(:status).each { |status, count| lines << "| #{status} | #{count} | #{@results.count { |r| r.status == status && r.review_needed }} |" }
      lines.concat(["", "## Route counts", "", "| Route | Rows |", "|---|---:|"])
      counts(:route).each { |route, count| lines << "| #{route} | #{count} |" }
      lines.concat([
        "", "## Review-needed meanings", "",
        "`manual` means a real publication/source is identified but has no verified stored, OA, or direct route and needs manual retrieval. `unresolved` means evidence or a usable route could not be verified, including API/network failures; it is not a judgment that the artifact is absent. `lost-candidate` means software has no artifact-specific retrieval route, the inventory explicitly documents an unlocated original, or a software URL repeatedly returned 404/410 without a located Wayback capture; one failed request is never treated as loss.",
        "", "Review-needed rows are exactly those marked `true` in the CSV. `manual`, `unresolved`, and `lost-candidate` remain separate statuses.",
        "", "## Review needed", "",
        "| Artifact | Requirement | Status | Route | Evidence |", "|---|---|---|---|---|"
      ])
      @results.select(&:review_needed).each do |result|
        lines << "| `#{result.id}` | #{result.requirement} | #{result.status} | #{result.route} | #{escape(result.evidence)} |"
      end
      lines.concat(["", "None."]) if @results.none?(&:review_needed)
      lines.concat(["", "## Network limitations", ""])
      network_note = if @network_stats[:resumed]
        "Base audit resumed from its previous CSV and reconciled with curated local/source evidence; no new network requests were made."
      elsif @network_stats.empty?
        "No network statistics supplied (test or offline construction)."
      else
        "Network requests: #{@network_stats[:requests] || 0}. Individual request failures are preserved in the relevant evidence cells; failed or blocked checks remain `unresolved` rather than false successes."
      end
      lines << network_note
      lines.concat(["", "## Complete audit", "", "| Artifact | Requirement | Status | Route | Confidence | Item | Evidence |", "|---|---|---|---|---|---|---|"])
      @results.each do |result|
        item = [result.item_key, result.item_title].compact.reject(&:empty?).join(" — ")
        lines << "| `#{result.id}` | #{result.requirement} | #{result.status} | #{result.route} | #{result.confidence} | #{escape(item)} | #{escape(result.evidence)} |"
      end
      lines.join("\n") + "\n"
    end

    def counts(field)
      @results.group_by(&field).map { |value, rows| [value, rows.size] }.sort_by { |value, _| value }
    end

    def escape(value)
      value.to_s.gsub("|", "\\|").gsub(/\s*\n\s*/, " ")
    end

    def atomic_write(path, content)
      directory = File.dirname(path)
      Tempfile.create([File.basename(path), ".tmp"], directory) do |file|
        file.write(content)
        file.flush
        file.close
        File.rename(file.path, path)
      end
    end
  end

  def self.resume_results(path, artifacts)
    rows = CSV.read(path, headers: true).map(&:to_h)
    raise "resumed audit row count does not match inventory" unless rows.size == artifacts.size
    rows_by_id = rows.each_with_object({}) { |row, by_id| by_id[row.fetch("artifact_id")] = row }
    artifacts.map do |artifact|
      row = rows_by_id.fetch(artifact.id)
      Result.new(artifact: artifact, status: row["status"], route: row["route"], confidence: row["confidence"],
        attachment_key: row["attachment_key"], evidence_url: row["evidence_url"], evidence: row["evidence"],
        review_needed: row["review_needed"] == "true")
    end
  end

  def self.apply_overrides(results, path)
    overrides = File.exist?(path) ? YAML.load_file(path) : {}
    unknown = overrides.keys - results.map(&:id)
    raise "override IDs not in inventory: #{unknown.join(", ")}" unless unknown.empty?
    results.map do |result|
      override = overrides[result.id]
      next result unless override
      required = %w[status route confidence evidence review_needed]
      missing = required.select { |field| !override.key?(field) }
      raise "override #{result.id} lacks #{missing.join(", ")}" unless missing.empty?
      Result.new(artifact: result.artifact, status: override["status"], route: override["route"],
        confidence: override["confidence"], attachment_key: nil, evidence_url: override["evidence_url"],
        evidence: override["evidence"], review_needed: override["review_needed"])
    end
  end

  def self.run(options)
    snapshot = Snapshot.new(options[:snapshot])
    artifacts = Inventory.new(options[:sheet], snapshot, snapshot_path: options[:snapshot]).artifacts
    client = HttpClient.new
    results = if options[:resume]
      resume_results(options[:resume], artifacts)
    else
      classifier = Classifier.new(snapshot, client: client, network: options[:network])
      artifacts.each_with_index.map do |artifact, index|
        warn "[#{index + 1}/#{artifacts.size}] #{artifact.id}" if options[:verbose]
        classifier.classify(artifact)
      end
    end
    results = apply_overrides(results, options[:overrides] || OVERRIDES)
    Writer.new(results, sheet_path: options[:sheet], snapshot_path: options[:snapshot],
      network_stats: {requests: client.requests.size, resumed: !options[:resume].nil?}).write(options[:csv], options[:markdown])
    results.group_by(&:status).sort.each { |status, rows| puts "#{status}: #{rows.size}" }
    puts "Wrote #{results.size} rows to #{options[:csv]}"
    puts "Wrote review document to #{options[:markdown]}"
    puts "Network requests: #{client.requests.size}"
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    sheet: ZoteroInventoryAudit::SHEET,
    snapshot: ZoteroInventoryAudit::SNAPSHOT,
    csv: ZoteroInventoryAudit::OUT_CSV,
    markdown: ZoteroInventoryAudit::OUT_MD,
    network: true,
    verbose: true
  }
  OptionParser.new do |parser|
    parser.on("--offline") { options[:network] = false }
    parser.on("--quiet") { options[:verbose] = false }
    parser.on("--sheet PATH") { |path| options[:sheet] = path }
    parser.on("--snapshot PATH") { |path| options[:snapshot] = path }
    parser.on("--csv PATH") { |path| options[:csv] = path }
    parser.on("--markdown PATH") { |path| options[:markdown] = path }
    parser.on("--resume PATH") { |path| options[:resume] = path }
    parser.on("--overrides PATH") { |path| options[:overrides] = path }
  end.parse!
  ZoteroInventoryAudit.run(options)
end
