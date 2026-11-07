require "digest"
require "fileutils"
require "json"
require "net/http"
require "nokogiri"
require "open3"
require "pathname"
require "tempfile"
require "time"
require "tmpdir"
require "uri"

module ZoteroAcquisition
  ROOT = File.expand_path("../..", __dir__)
  SCHEMA_VERSION = 1
  TERMINAL_STATUSES = %w[acquired failed manual reference-only absent-expected].freeze
  REQUIREMENTS = %w[required optional].freeze
  SATISFIED_STATUSES = %w[acquired reference-only].freeze
  USER_AGENT = "CorpusBuilderPhase3Acquisition/1.0 (Emerging Philosophy private-research preservation)"

  Route = Struct.new(:artifact_id, :audit_unit, :requirement, :status, :route, :evidence_url,
    :evidence, :attachment_key, :item_title, :source_url, :expectations, keyword_init: true)

  ProcessResult = Struct.new(:artifact_id, :action, :terminal_status, :object_id, :error, keyword_init: true)

  module Data
    module_function

    def stringify(hash)
      return {} if hash.nil?
      hash.each_with_object({}) { |(key, value), result| result[key.to_s] = value }
    end

    def present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end
  end

  module Manifest
    module_function

    def slot(attributes)
      data = {
        "schema_version" => SCHEMA_VERSION,
        "manifest_type" => "artifact-slot",
        "source_urls" => [],
        "final_url" => nil,
        "provenance" => {},
        "version_edition" => nil,
        "fetched_at" => nil,
        "user_agent" => USER_AGENT,
        "attempts" => [],
        "qualifications" => [],
        "expectations" => {},
        "object_id" => nil
      }.merge(Data.stringify(attributes))
      data["object_manifest"] = data["object_id"] ? "objects/#{data["object_id"]}/manifest.json" : nil
      validate_slot!(data)
      data
    end

    def object(attributes)
      data = {
        "schema_version" => SCHEMA_VERSION,
        "manifest_type" => "physical-object",
        "identities" => [],
        "expectations" => {},
        "provenance" => [],
        "slot_ids" => [],
        "slot_manifests" => [],
        "created_at" => Time.now.utc.iso8601,
        "updated_at" => Time.now.utc.iso8601
      }.merge(Data.stringify(attributes))
      verification = data.fetch("verification", {})
      %w[size sha256 md5 remote_url head shallow worktree_clean submodules fsck file_count total_size inventory_sha256 files software_version].each do |field|
        data[field] = verification[field] if verification.key?(field)
      end
      validate_object!(data)
      data
    end

    def validate_slot!(data)
      validate_artifact_id!(data["artifact_id"])
      raise ArgumentError, "slot audit unit does not match artifact ID" unless data["audit_unit"] == data["artifact_id"].split("/").first
      raise ArgumentError, "invalid slot requirement" unless REQUIREMENTS.include?(data["requirement"])
      raise ArgumentError, "invalid terminal status" unless TERMINAL_STATUSES.include?(data["terminal_status"])
      raise ArgumentError, "slot route is required" unless Data.present?(data["route"])
      raise ArgumentError, "slot schema version mismatch" unless data["schema_version"] == SCHEMA_VERSION
      raise ArgumentError, "slot manifest type mismatch" unless data["manifest_type"] == "artifact-slot"
      raise ArgumentError, "slot source URLs must be an array" unless data["source_urls"].is_a?(Array)
      raise ArgumentError, "slot attempts must be an array" unless data["attempts"].is_a?(Array)
      raise ArgumentError, "slot verification must be an object" unless data["verification"].is_a?(Hash)
      raise ArgumentError, "slot expectations must be an object" if data.key?("expectations") && !data["expectations"].is_a?(Hash)
      raise ArgumentError, "slot outcome evidence is required" unless Data.present?(data["verification"]["evidence"])

      if data["terminal_status"] == "acquired"
        raise ArgumentError, "acquired slot requires an object" unless Data.present?(data["object_id"])
        raise ArgumentError, "acquired slot requires passed verification" unless data["verification"]["status"] == "passed"
      end
      true
    end

    def validate_object!(data)
      validate_object_id!(data["object_id"])
      raise ArgumentError, "object schema version mismatch" unless data["schema_version"] == SCHEMA_VERSION
      raise ArgumentError, "object manifest type mismatch" unless data["manifest_type"] == "physical-object"
      raise ArgumentError, "object kind is invalid" unless %w[file directory repository].include?(data["kind"])
      raise ArgumentError, "object path is required" unless Data.present?(data["path"])
      raise ArgumentError, "object identities are required" unless data["identities"].is_a?(Array) && !data["identities"].empty?
      raise ArgumentError, "object verification must be an object" unless data["verification"].is_a?(Hash)
      raise ArgumentError, "object slot links must be arrays" unless data["slot_ids"].is_a?(Array) && data["slot_manifests"].is_a?(Array)
      raise ArgumentError, "object slot link counts differ" unless data["slot_ids"].size == data["slot_manifests"].size

      case data["kind"]
      when "file"
        raise ArgumentError, "file size is invalid" unless data["size"].is_a?(Integer) && data["size"] >= 0
        raise ArgumentError, "file SHA256 is invalid" unless data["sha256"].to_s.match?(/\A\h{64}\z/)
        raise ArgumentError, "file media type is required" unless Data.present?(data["media_type"])
      when "directory"
        raise ArgumentError, "directory size is invalid" unless data["size"].is_a?(Integer) && data["size"] >= 0
        raise ArgumentError, "directory file count is invalid" unless data["file_count"].is_a?(Integer) && data["file_count"] >= 0
        raise ArgumentError, "directory inventory is invalid" unless data["files"].is_a?(Array)
        raise ArgumentError, "directory inventory SHA256 is invalid" unless data["inventory_sha256"].to_s.match?(/\A\h{64}\z/)
      else
        raise ArgumentError, "repository HEAD is invalid" unless data["head"].to_s.match?(/\A\h{40}\z/)
        raise ArgumentError, "repository remote is required" unless Data.present?(data["remote_url"])
        raise ArgumentError, "repository shallow flag is invalid" unless [true, false].include?(data["shallow"])
        raise ArgumentError, "repository worktree flag is invalid" unless [true, false].include?(data["worktree_clean"])
        raise ArgumentError, "repository fsck result is required" unless data["fsck"].is_a?(Hash) && Data.present?(data["fsck"]["status"])
        raise ArgumentError, "repository clone exit status is required" unless data.dig("clone_status", "exit_status").is_a?(Integer)
      end
      true
    end

    def validate_artifact_id!(id)
      return true if id.to_s.match?(/\AEP-\d{3,}\/[a-z][a-z0-9_-]*\/[A-Za-z0-9][A-Za-z0-9_-]*\z/)
      raise ArgumentError, "invalid artifact ID: #{id.inspect}"
    end

    def validate_object_id!(id)
      return true if id.to_s.match?(/\A[a-z0-9][a-z0-9.-]*\z/) && !id.to_s.include?("..")
      raise ArgumentError, "invalid object ID: #{id.inspect}"
    end
  end

  class Store
    attr_reader :root

    def initialize(root, project_root: ROOT)
      @root = File.expand_path(root)
      @project_root = File.expand_path(project_root)
    end

    def slot_path(artifact_id)
      Manifest.validate_artifact_id!(artifact_id)
      File.join(@root, "slots", artifact_id, "manifest.json")
    end

    def object_directory(object_id)
      Manifest.validate_object_id!(object_id)
      File.join(@root, "objects", object_id)
    end

    def object_path(object_id)
      File.join(object_directory(object_id), "manifest.json")
    end

    def read_slot(artifact_id)
      read_if_present(slot_path(artifact_id))
    end

    def read_object(object_id)
      read_if_present(object_path(object_id))
    end

    def write_slot(data)
      Manifest.validate_slot!(data)
      atomic_json(slot_path(data.fetch("artifact_id")), data)
      data
    end

    def write_object(data)
      Manifest.validate_object!(data)
      atomic_json(object_path(data.fetch("object_id")), data)
      data
    end

    def slots
      Dir.glob(File.join(@root, "slots", "**", "manifest.json")).sort.map do |path|
        data = JSON.parse(File.read(path))
        Manifest.validate_slot!(data)
        raise ArgumentError, "slot path and artifact ID disagree: #{path}" unless File.expand_path(slot_path(data.fetch("artifact_id"))) == File.expand_path(path)
        data
      end
    end

    def objects
      Dir.glob(File.join(@root, "objects", "*", "manifest.json")).sort.map do |path|
        data = JSON.parse(File.read(path))
        Manifest.validate_object!(data)
        raise ArgumentError, "object path and object ID disagree: #{path}" unless File.expand_path(object_path(data.fetch("object_id"))) == File.expand_path(path)
        data
      end
    end

    def find_object(identity)
      objects.find { |object| object.fetch("identities").include?(identity) }
    end

    def find_object_by_sha256(sha256)
      objects.find { |object| object["kind"] == "file" && object["sha256"] == sha256 }
    end

    def rebuild_registry!
      object_rows = objects
      slot_rows = slots
      by_id = {}
      paths = {}
      identities = {}
      hashes = {}

      object_rows.each do |object|
        id = object.fetch("object_id")
        raise ArgumentError, "duplicate object ID #{id}" if by_id.key?(id)
        by_id[id] = object
        path = canonical_path(expand_path(object.fetch("path")))
        raise ArgumentError, "physical path has multiple object manifests: #{path}" if paths.key?(path)
        paths[path] = id
        object.fetch("identities").each do |identity|
          raise ArgumentError, "object identity collision: #{identity}" if identities.key?(identity)
          identities[identity] = id
        end
        if object["kind"] == "file" && object["sha256"]
          raise ArgumentError, "content hash has multiple objects: #{object["sha256"]}" if hashes.key?(object["sha256"])
          hashes[object["sha256"]] = id
        end
      end

      slot_rows.each do |slot|
        object_id = slot["object_id"]
        next unless object_id
        raise ArgumentError, "slot references unknown object #{object_id}" unless by_id.key?(object_id)
      end

      object_rows.each do |object|
        linked = slot_rows.select { |slot| slot["object_id"] == object["object_id"] }
        raise ArgumentError, "object has no dependent slots: #{object["object_id"]}" if linked.empty?
        expected_ids = linked.map { |slot| slot.fetch("artifact_id") }.sort
        expected_paths = linked.map { |slot| relative_root(slot_path(slot.fetch("artifact_id"))) }.sort
        raise ArgumentError, "object slot IDs disagree: #{object["object_id"]}" unless object.fetch("slot_ids").sort == expected_ids
        raise ArgumentError, "object slot paths disagree: #{object["object_id"]}" unless object.fetch("slot_manifests").sort == expected_paths
      end

      registry = {
        "schema_version" => SCHEMA_VERSION,
        "generated_at" => Time.now.utc.iso8601,
        "objects" => object_rows.map do |object|
          {
            "object_id" => object["object_id"],
            "kind" => object["kind"],
            "path" => object["path"],
            "sha256" => object["sha256"],
            "identities" => object["identities"],
            "slot_ids" => object["slot_ids"],
            "manifest" => relative_root(object_path(object["object_id"]))
          }
        end,
        "slots" => slot_rows.map do |slot|
          {
            "artifact_id" => slot["artifact_id"],
            "object_id" => slot["object_id"],
            "terminal_status" => slot["terminal_status"],
            "manifest" => relative_root(slot_path(slot["artifact_id"]))
          }
        end
      }
      atomic_json(File.join(@root, "registry.json"), registry)
      registry
    end

    def write_coverage(routes)
      rows = routes.map do |route|
        slot = read_slot(route.artifact_id)
        {
          "artifact_id" => route.artifact_id,
          "audit_unit" => route.audit_unit,
          "requirement" => route.requirement,
          "status" => slot ? slot.fetch("terminal_status") : "pending",
          "object_id" => slot && slot["object_id"],
          "manifest" => slot ? relative_root(slot_path(route.artifact_id)) : nil
        }
      end
      coverage = {
        "schema_version" => SCHEMA_VERSION,
        "generated_at" => Time.now.utc.iso8601,
        "total_slots" => rows.size,
        "required" => coverage_group(rows, "required"),
        "optional" => coverage_group(rows, "optional"),
        "complete" => rows.all? { |row| TERMINAL_STATUSES.include?(row["status"]) },
        "slots" => rows
      }
      atomic_json(File.join(@root, "coverage.json"), coverage)
      coverage
    end

    def registry
      JSON.parse(File.read(File.join(@root, "registry.json")))
    end

    def record_path(path)
      expanded = File.expand_path(path)
      prefix = @project_root + File::SEPARATOR
      expanded.start_with?(prefix) ? expanded.sub(prefix, "") : expanded
    end

    def expand_path(path)
      return path if Pathname.new(path).absolute?
      File.expand_path(path, @project_root)
    end

    private

    def coverage_group(rows, requirement)
      selected = rows.select { |row| row["requirement"] == requirement }
      counts = Hash.new(0)
      selected.each { |row| counts[row["status"]] += 1 }
      satisfied = selected.count { |row| SATISFIED_STATUSES.include?(row["status"]) }
      {
        "total" => selected.size,
        "satisfied" => satisfied,
        "missing" => selected.size - satisfied,
        "by_status" => counts.sort.to_h
      }
    end

    def canonical_path(path)
      File.realpath(path)
    rescue Errno::ENOENT
      File.expand_path(path)
    end

    def relative_root(path)
      Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
    end

    def read_if_present(path)
      File.exist?(path) ? JSON.parse(File.read(path)) : nil
    end

    def atomic_json(path, data)
      FileUtils.mkdir_p(File.dirname(path))
      Tempfile.create([File.basename(path), ".tmp"], File.dirname(path)) do |file|
        file.write(JSON.pretty_generate(data) + "\n")
        file.flush
        file.close
        File.rename(file.path, path)
      end
    end
  end

  class FileVerifier
    def verify(path, expectations = {})
      expectations = Data.stringify(expectations)
      result = {
        "kind" => "file",
        "status" => "passed",
        "size" => nil,
        "sha256" => nil,
        "md5" => nil,
        "checks" => [],
        "format" => {},
        "identity" => {},
        "extent" => {},
        "verified_at" => Time.now.utc.iso8601
      }
      unless File.file?(path)
        result["status"] = "failed"
        result["checks"] << check("file", "failed", "not a regular file: #{path}")
        return result
      end

      result["size"] = File.size(path)
      result["sha256"] = Digest::SHA256.file(path).hexdigest
      result["md5"] = Digest::MD5.file(path).hexdigest
      verify_digest(result, expectations, "size")
      verify_digest(result, expectations, "sha256")
      verify_digest(result, expectations, "md5")

      media_type = expectations["media_type"] || inferred_media_type(path)
      result["media_type"] = media_type
      if media_type == "application/pdf"
        verify_pdf(result, path, expectations)
      elsif media_type == "text/html"
        verify_html(result, path, expectations)
      elsif media_type.include?("xml") || expectations["text_markers"]
        verify_text(result, path, expectations)
      end
      verify_content_review(result, expectations)
      result["status"] = "failed" if result["checks"].any? { |entry| entry["status"] == "failed" }
      result
    end

    private

    def verify_digest(result, expectations, field)
      return unless expectations[field]
      expected = expectations[field]
      actual = result[field]
      result["checks"] << check(field, (expected == actual) ? "passed" : "failed", {"expected" => expected, "actual" => actual})
    end

    def verify_pdf(result, path, expectations)
      magic = File.binread(path, 4)
      result["checks"] << check("pdf_magic", (magic == "%PDF") ? "passed" : "failed", magic.inspect)
      info = command("pdfinfo", path)
      if info && info[:status].success?
        metadata = parse_pdfinfo(info[:stdout])
        result["format"] = metadata
        result["extent"] = {"pages" => metadata["pages"].to_i}
        result["checks"] << check("pdfinfo", "passed", metadata)
      elsif info.nil?
        result["checks"] << check("pdfinfo", "unavailable", "pdfinfo unavailable")
      else
        evidence = info[:stderr].to_s.empty? ? info[:stdout] : info[:stderr]
        result["checks"] << check("pdfinfo", "failed", evidence)
      end
      if expectations["pages"]
        actual = result["extent"]["pages"].to_i
        expected = expectations["pages"].to_i
        result["checks"] << check("pdf_page_count", (actual == expected) ? "passed" : "failed", {"expected" => expected, "actual" => actual})
      end

      text_pages = (expectations["text_pages"] || 2).to_i
      result["extent"]["text_pages"] = text_pages
      extraction = command("pdftotext", "-f", "1", "-l", text_pages.to_s, path, "-")
      text = (extraction && extraction[:status].success?) ? extraction[:stdout] : ""
      extraction_status = if extraction.nil?
        "unavailable"
      elsif extraction[:status].success?
        "passed"
      else
        "failed"
      end
      result["checks"] << check("pdftotext", extraction_status, extraction ? extraction[:stderr].to_s : "pdftotext unavailable")
      verify_title(result, expectations["title"], [result["format"]["title"], text].compact.join("\n"))
      result["identity"]["text_excerpt"] = text[0, 2000]
      verify_ocr(result, path, expectations) unless Array(expectations["ocr_pages"]).empty?
    end

    def verify_content_review(result, expectations)
      review = expectations["content_review"]
      return unless review
      raise ArgumentError, "invalid content review status" unless %w[passed failed].include?(review["status"])
      result["identity"]["content_review"] = review
      result["checks"] << check("content_review", review["status"], review["evidence"])
    end

    def verify_ocr(result, path, expectations)
      dpi = (expectations["ocr_dpi"] || 200).to_i.to_s
      pages = Array(expectations["ocr_pages"])
      combined = +""
      pages.each do |page|
        image = command("pdftoppm", "-f", page.to_s, "-l", page.to_s, "-r", dpi, "-png", "-singlefile", path)
        ocr = (image && image[:status].success?) ? command_with_input(image[:stdout], "tesseract", "stdin", "stdout") : nil
        if ocr && ocr[:status].success?
          text = ocr[:stdout].scrub
          combined << "\n" << text
          result["checks"] << check("ocr_page_#{page}", "passed", {"dpi" => dpi.to_i, "characters" => text.length})
        else
          evidence = if image && !image[:status].success?
            image[:stderr].to_s
          else
            ocr && ocr[:stderr].to_s
          end
          result["checks"] << check("ocr_page_#{page}", "failed", evidence.to_s.empty? ? "OCR unavailable" : evidence)
        end
      end
      result["extent"]["ocr_pages"] = pages
      result["identity"]["ocr_excerpt"] = combined[0, 2000]
      markers = Array(expectations["ocr_markers"])
      return if markers.empty?

      matched = markers.all? { |marker| combined.downcase.include?(marker.scrub.downcase) }
      result["identity"]["ocr_markers"] = markers
      result["identity"]["ocr_markers_matched"] = matched
      result["checks"] << check("ocr_markers", matched ? "passed" : "failed", markers)
    end

    def verify_html(result, path, expectations)
      content = File.binread(path)
      document = Nokogiri::HTML(content)
      named_anchors = document.css("a[name]").map { |node| node["name"] }.uniq.size
      internal_links = document.css("a[href]").count { |node| node["href"].to_s.start_with?("#") }
      result["format"] = {
        "title" => document.at_css("title")&.text.to_s,
        "named_anchors" => named_anchors,
        "internal_links" => internal_links,
        "parse_errors" => document.errors.size
      }
      searchable = document.text
      searchable = searchable.encode("UTF-8", invalid: :replace, replace: "�") unless searchable.encoding == Encoding::UTF_8
      searchable = searchable.scrub
      markers = Array(expectations["html_markers"])
      matched = markers.all? { |marker| searchable.downcase.include?(marker.scrub.downcase) }
      result["identity"] = {"markers" => markers, "markers_matched" => matched}
      result["checks"] << check("html_identity", matched ? "passed" : "failed", markers) unless markers.empty?
      verify_title(result, expectations["title"], searchable) if markers.empty?
      if expectations["anchor_count"]
        actual = named_anchors
        expected = expectations["anchor_count"]
        result["checks"] << check("html_anchor_count", (actual == expected) ? "passed" : "failed", {"expected" => expected, "actual" => actual})
      end
      result["checks"] << check("html_parse", "passed", "HTML parsed")
    rescue ArgumentError => e
      result["checks"] << check("html_parse", "failed", e.message)
    end

    def verify_text(result, path, expectations)
      content = File.binread(path)
      content = content.encode("UTF-8", invalid: :replace, replace: "�") unless content.encoding == Encoding::UTF_8
      searchable = content.scrub
      if result["media_type"].include?("xml")
        document = Nokogiri::XML(searchable) { |config| config.strict }
        result["format"] = {"root_name" => document.root&.name, "parse_errors" => 0}
        result["checks"] << check("xml_parse", "passed", "XML parsed")
      end
      markers = Array(expectations["text_markers"])
      matched = markers.all? { |marker| searchable.downcase.include?(marker.scrub.downcase) }
      result["identity"] = {"markers" => markers, "markers_matched" => matched}
      result["checks"] << check("text_identity", matched ? "passed" : "failed", markers) unless markers.empty?
      verify_title(result, expectations["title"], searchable) if markers.empty?
    rescue Nokogiri::XML::SyntaxError, ArgumentError => e
      result["checks"] << check("xml_parse", "failed", e.message)
    end

    def verify_title(result, expected_title, actual_text)
      return unless Data.present?(expected_title)
      expected = normalize(expected_title)
      actual = normalize(actual_text)
      matched = !expected.empty? && actual.include?(expected)
      result["identity"] = result["identity"].merge("expected_title" => expected_title, "title_matched" => matched)
      result["checks"] << check("identity_title", matched ? "passed" : "failed", {"expected" => expected_title})
    end

    def parse_pdfinfo(output)
      fields = {}
      output.to_s.each_line do |line|
        key, value = line.split(":", 2)
        next unless value
        normalized = key.strip.downcase.tr(" ", "_")
        fields[normalized] = value.strip if %w[title author pages pdf_version encrypted].include?(normalized)
      end
      fields
    end

    def command(*arguments)
      stdout, stderr, status = Open3.capture3(*arguments)
      {stdout: stdout, stderr: stderr, status: status}
    rescue Errno::ENOENT
      nil
    end

    def command_with_input(input, *arguments)
      stdout, stderr, status = Open3.capture3(*arguments, stdin_data: input)
      {stdout: stdout, stderr: stderr, status: status}
    rescue Errno::ENOENT
      nil
    end

    def normalize(text)
      normalized = text.to_s.unicode_normalize(:nfkd).downcase
      normalized = normalized.gsub("œ", "oe").gsub("æ", "ae").gsub("þ", "th").tr("øðł", "odl")
      normalized.gsub(/[^a-z0-9]+/, " ").strip
    end

    def inferred_media_type(path)
      extension = File.extname(path).downcase
      return "application/pdf" if extension == ".pdf"
      return "text/html" if %w[.html .htm].include?(extension)

      header = File.binread(path, 4096)
      return "application/pdf" if header.start_with?("%PDF")
      return "text/html" if header.match?(/<\s*(?:!doctype\s+html|html|head|body|title)\b/i)
      "application/octet-stream"
    end

    def check(name, status, evidence)
      {"name" => name, "status" => status, "evidence" => evidence}
    end
  end

  class DirectoryVerifier
    def initialize(file_verifier: FileVerifier.new)
      @file_verifier = file_verifier
    end

    def verify(path, expectations = {})
      expectations = Data.stringify(expectations)
      result = {
        "kind" => "directory",
        "status" => "passed",
        "size" => nil,
        "files" => [],
        "file_count" => 0,
        "total_size" => 0,
        "inventory_sha256" => nil,
        "checks" => [],
        "documents" => [],
        "identity" => {},
        "verified_at" => Time.now.utc.iso8601
      }
      unless File.directory?(path)
        result["status"] = "failed"
        result["checks"] << check("directory", "failed", "not a directory: #{path}")
        return result
      end

      paths = Dir.glob(File.join(path, "**", "*")).select { |entry| File.file?(entry) }.sort
      entries = paths.map do |entry|
        relative = Pathname.new(entry).relative_path_from(Pathname.new(path)).to_s
        {"path" => relative, "size" => File.size(entry), "sha256" => Digest::SHA256.file(entry).hexdigest}
      end
      result["files"] = entries
      result["size"] = entries.sum { |entry| entry["size"] }
      result["total_size"] = result["size"]
      result["file_count"] = entries.size
      result["inventory_sha256"] = Digest::SHA256.hexdigest(JSON.generate(entries))
      symlinks = paths.select { |entry| File.symlink?(entry) }
      result["checks"] << check("no_symlinks", symlinks.empty? ? "passed" : "failed", symlinks)

      expected_files = Data.stringify(expectations["files"])
      actual_by_path = entries.to_h { |entry| [entry["path"], entry] }
      unless expected_files.empty?
        missing = expected_files.keys - actual_by_path.keys
        unexpected = actual_by_path.keys - expected_files.keys
        result["checks"] << check("file_set", (missing.empty? && unexpected.empty?) ? "passed" : "failed",
          {"missing" => missing, "unexpected" => unexpected})
        mismatches = expected_files.keys.select do |relative|
          actual_by_path[relative] && actual_by_path[relative]["sha256"] != expected_files[relative]
        end
        result["checks"] << check("file_hashes", mismatches.empty? ? "passed" : "failed", mismatches)
      end
      verify_expectation(result, "file_count", expectations["file_count"], entries.size)
      verify_expectation(result, "inventory_sha256", expectations["inventory_sha256"], result["inventory_sha256"])
      verify_markers(result, path, expectations["content_markers"])
      verify_documents(result, path, entries)
      verify_software_version(result, path, entries, expectations["software_version"])
      result["status"] = "failed" if result["checks"].any? { |entry| entry["status"] == "failed" }
      result
    end

    private

    def verify_expectation(result, name, expected, actual)
      return unless expected
      result["checks"] << check(name, (expected == actual) ? "passed" : "failed", {"expected" => expected, "actual" => actual})
    end

    def verify_markers(result, path, marker_map)
      Data.stringify(marker_map).each do |relative, markers|
        full_path = safe_path(path, relative)
        matched = full_path && File.file?(full_path) && Array(markers).all? do |marker|
          File.binread(full_path).downcase.include?(marker.scrub.downcase)
        end
        result["identity"][relative] = {"markers" => markers, "matched" => !!matched}
        result["checks"] << check("content_markers_#{relative}", matched ? "passed" : "failed", markers)
      end
    end

    def verify_documents(result, path, entries)
      pdf_entries = entries.select { |entry| File.extname(entry["path"]).downcase == ".pdf" }
      return if pdf_entries.empty?

      documents = pdf_entries.map do |entry|
        verification = @file_verifier.verify(File.join(path, entry["path"]), "media_type" => "application/pdf")
        {
          "path" => entry["path"],
          "status" => verification["status"],
          "pages" => verification.dig("extent", "pages"),
          "sha256" => verification["sha256"]
        }
      end
      result["documents"] = documents
      failed = documents.reject { |document| document["status"] == "passed" }
      result["checks"] << check("pdf_documents", failed.empty? ? "passed" : "failed", failed)
    end

    def verify_software_version(result, path, entries, expected)
      versions = entries.select { |entry| entry["path"].end_with?(".lisp") }.flat_map do |entry|
        File.binread(File.join(path, entry["path"])).scan(/\*version\*\s*(?:=\s*)?"([^"]+)"/).flatten
      end.uniq
      result["software_version"] = versions.join(",") unless versions.empty?
      verify_expectation(result, "software_version", expected, result["software_version"])
    end

    def safe_path(path, relative)
      pathname = Pathname.new(relative)
      return nil if pathname.absolute? || pathname.each_filename.to_a.include?("..")
      File.join(path, relative)
    end

    def check(name, status, evidence)
      {"name" => name, "status" => status, "evidence" => evidence}
    end
  end

  class RepositoryVerifier
    def verify(path, expectations = {})
      expectations = Data.stringify(expectations)
      result = {
        "kind" => "repository",
        "status" => "passed",
        "checks" => [],
        "verified_at" => Time.now.utc.iso8601
      }
      unless File.directory?(path)
        result["status"] = "failed"
        result["checks"] << {"name" => "repository", "status" => "failed", "evidence" => "not a directory: #{path}"}
        return result
      end

      remote = git(path, "remote", "get-url", "origin")
      head = git(path, "rev-parse", "HEAD")
      shallow = git(path, "rev-parse", "--is-shallow-repository")
      fsck = git(path, "fsck", "--full")
      worktree = git(path, "status", "--porcelain")
      submodules = git(path, "submodule", "status")
      result["remote_url"] = remote[:stdout].strip
      result["head"] = head[:stdout].strip
      result["shallow"] = shallow[:stdout].strip == "true"
      result["worktree_clean"] = worktree[:status].success? && worktree[:stdout].strip.empty?
      result["fsck"] = command_check("git_fsck", fsck)
      result["submodules"] = parse_submodules(submodules[:stdout])
      result["checks"] << command_check("git_remote", remote)
      result["checks"] << command_check("git_head", head)
      result["checks"] << command_check("git_shallow", shallow)
      result["checks"] << result["fsck"]
      result["checks"] << check("git_worktree", result["worktree_clean"] ? "passed" : "failed", worktree[:stdout].strip)
      result["checks"] << command_check("git_submodules", submodules)
      verify_expectation(result, "remote_url", expectations["remote_url"], result["remote_url"])
      verify_expectation(result, "head", expectations["head"], result["head"])
      result["status"] = "failed" if result["checks"].any? { |entry| entry["status"] == "failed" }
      result
    end

    private

    def verify_expectation(result, name, expected, actual)
      return unless expected
      result["checks"] << check("expected_#{name}", (expected == actual) ? "passed" : "failed", {"expected" => expected, "actual" => actual})
    end

    def git(path, *arguments)
      stdout, stderr, status = Open3.capture3("git", "-C", path, *arguments)
      {stdout: stdout, stderr: stderr, status: status}
    end

    def command_check(name, command)
      check(name, command[:status].success? ? "passed" : "failed",
        {"exit_status" => command[:status].exitstatus, "stdout" => command[:stdout][0, 2000], "stderr" => command[:stderr][0, 2000]})
    end

    def parse_submodules(output)
      output.to_s.each_line.map do |line|
        match = line.strip.match(/\A(.?)([0-9a-f]{40})\s+([^\s]+)(?:\s+(.*))?\z/)
        match ? {"state" => match[1], "head" => match[2], "path" => match[3], "description" => match[4]} : {"path" => line.strip}
      end
    end

    def check(name, status, evidence)
      {"name" => name, "status" => status, "evidence" => evidence}
    end
  end

  class HttpDownloader
    MAX_ATTEMPTS = 3
    REDIRECT_LIMIT = 5
    SENSITIVE_QUERY = /\A(?:.*(?:signature|credential|security-token).*|token|authorization|api[-_]?key|key|expires|awsaccesskeyid)\z/i

    def initialize(timeout: 30, delay: 1.0, sleeper: Kernel.method(:sleep))
      @timeout = timeout
      @delay = delay
      @sleeper = sleeper
      @last_request = nil
    end

    def self.sanitize_url(url)
      uri = URI.parse(url.to_s)
      if uri.query
        query = URI.decode_www_form(uri.query).reject { |key, _| key.match?(SENSITIVE_QUERY) }
        uri.query = query.empty? ? nil : URI.encode_www_form(query)
      end
      uri.userinfo = nil if uri.respond_to?(:userinfo=)
      uri.to_s
    rescue URI::InvalidURIError, ArgumentError
      url.to_s.gsub(/(signature|credential|token|api[-_]?key)=([^&\s]+)/i, "\\1=REDACTED")
    end

    def get(url, destination, headers: {})
      attempts = []
      source_urls = [self.class.sanitize_url(url)]
      current = url
      current_headers = headers.dup
      redirects = 0
      loop do
        result = request_with_retries(current, destination, current_headers, attempts)
        location = result[:location]
        unless result[:status].to_i.between?(300, 399) && location
          return {
            "success" => result[:status].to_i == 200 && result[:error].nil?,
            "http_status" => result[:status],
            "error" => result[:error],
            "source_urls" => source_urls,
            "final_url" => self.class.sanitize_url(current),
            "content_type" => result[:content_type],
            "fetched_at" => Time.now.utc.iso8601,
            "attempts" => attempts
          }
        end
        if redirects >= REDIRECT_LIMIT
          return {
            "success" => false,
            "error" => "too many redirects",
            "source_urls" => source_urls,
            "final_url" => self.class.sanitize_url(current),
            "fetched_at" => Time.now.utc.iso8601,
            "attempts" => attempts
          }
        end
        target = URI.join(current, location).to_s
        current_headers = current_headers.reject { |key, _| key.to_s.downcase == "authorization" } if URI.parse(target).host != URI.parse(current).host
        current = target
        source_urls << self.class.sanitize_url(current)
        redirects += 1
      end
    rescue URI::InvalidURIError => e
      {
        "success" => false,
        "error" => "invalid redirect: #{e.message}",
        "source_urls" => source_urls,
        "final_url" => self.class.sanitize_url(current),
        "fetched_at" => Time.now.utc.iso8601,
        "attempts" => attempts
      }
    end

    private

    def request_with_retries(url, destination, headers, attempts)
      MAX_ATTEMPTS.times do |index|
        result = perform(url, destination, headers, attempts)
        return result if result[:status].to_i.between?(200, 399) && !retryable?(result)
        return result unless retryable?(result)
        return result if index + 1 == MAX_ATTEMPTS
        @sleeper.call(0.5 * (2**index))
      end
    end

    def perform(url, destination, headers, attempts)
      throttle
      uri = URI.parse(url)
      raise URI::InvalidURIError, "only HTTP(S) URLs are supported" unless uri.is_a?(URI::HTTP) && uri.host
      attempt = {"method" => "GET", "url" => self.class.sanitize_url(url), "at" => Time.now.utc.iso8601, "attempt" => attempts.count { |entry| entry["url"] == self.class.sanitize_url(url) } + 1}
      attempts << attempt
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
        open_timeout: @timeout, read_timeout: @timeout, write_timeout: @timeout) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        headers.each { |key, value| request[key] = value }
        http.request(request) do |response|
          attempt["http_status"] = response.code.to_i
          attempt["content_type"] = response["content-type"]
          if response.code.to_i == 200
            File.open(destination, "wb") do |file|
              response.read_body { |chunk| file.write(chunk) }
            end
          end
          return {status: response.code.to_i, location: response["location"], error: nil, content_type: response["content-type"]}
        end
      end
    rescue => e
      attempts.last["error"] = "#{e.class}: #{e.message}" unless attempts.empty?
      {status: nil, location: nil, error: "#{e.class}: #{e.message}"}
    end

    def retryable?(result)
      result[:error] || [404, 410, 429].include?(result[:status].to_i) || result[:status].to_i >= 500
    end

    def throttle
      return unless @last_request
      remaining = @delay - (Time.now - @last_request)
      @sleeper.call(remaining) if remaining.positive?
    ensure
      @last_request = Time.now
    end
  end

  class AttachmentFetcher
    BASE_URL = "https://api.zotero.org"

    attr_reader :fetch_count

    def initialize(user_id:, api_key:, downloader: HttpDownloader.new)
      @user_id = user_id
      @api_key = api_key
      @downloader = downloader
      @fetch_count = 0
    end

    def fetch(key, destination)
      @fetch_count += 1
      url = "#{BASE_URL}/users/#{@user_id}/items/#{key}/file"
      @downloader.get(url, destination, headers: {"Authorization" => "Bearer #{@api_key}"})
    end
  end

  class RemoteFetcher
    attr_reader :fetch_count

    def initialize(downloader: HttpDownloader.new)
      @downloader = downloader
      @fetch_count = 0
    end

    def fetch(url, destination)
      @fetch_count += 1
      @downloader.get(url, destination)
    end
  end

  class GitFetcher
    attr_reader :fetch_count

    def initialize
      @fetch_count = 0
    end

    def clone(url, destination)
      @fetch_count += 1
      attempt = {"method" => "GIT CLONE", "url" => HttpDownloader.sanitize_url(url), "at" => Time.now.utc.iso8601, "attempt" => 1}
      stdout, stderr, status = Open3.capture3("git", "clone", url, destination)
      attempt.merge!("exit_status" => status.exitstatus, "stdout" => stdout[0, 2000], "stderr" => stderr[0, 2000])
      {
        "success" => status.success?,
        "error" => status.success? ? nil : "git clone exited #{status.exitstatus}",
        "source_urls" => [HttpDownloader.sanitize_url(url)],
        "final_url" => HttpDownloader.sanitize_url(url),
        "fetched_at" => Time.now.utc.iso8601,
        "attempts" => [attempt],
        "clone_status" => {"exit_status" => status.exitstatus}
      }
    rescue => e
      attempt["error"] = "#{e.class}: #{e.message}"
      {
        "success" => false,
        "error" => "#{e.class}: #{e.message}",
        "source_urls" => [HttpDownloader.sanitize_url(url)],
        "final_url" => HttpDownloader.sanitize_url(url),
        "fetched_at" => Time.now.utc.iso8601,
        "attempts" => [attempt],
        "clone_status" => {"exit_status" => 1}
      }
    end
  end

  class Runner
    def initialize(store, attachment_fetcher: nil, remote_fetcher: RemoteFetcher.new, git_fetcher: GitFetcher.new,
      file_verifier: FileVerifier.new, directory_verifier: DirectoryVerifier.new, repository_verifier: RepositoryVerifier.new,
      clock: -> { Time.now })
      @store = store
      @attachment_fetcher = attachment_fetcher
      @remote_fetcher = remote_fetcher
      @git_fetcher = git_fetcher
      @file_verifier = file_verifier
      @directory_verifier = directory_verifier
      @repository_verifier = repository_verifier
      @clock = clock
    end

    def process(route)
      existing = @store.read_slot(route.artifact_id)
      current_expectations = Data.stringify(route.expectations)
      if existing && existing["terminal_status"] == "acquired" &&
          Data.stringify(existing["expectations"]) == current_expectations && resumable?(existing)
        return ProcessResult.new(artifact_id: route.artifact_id, action: "skipped",
          terminal_status: "acquired", object_id: existing["object_id"])
      end

      if route.status == "present" && %w[local-file local-directory].include?(route.route)
        acquire_local(route, existing)
      elsif route.status == "present" && route.route == "zotero-stored-pdf"
        acquire_attachment(route, existing)
      elsif route.status == "clonable"
        acquire_repository(route, existing)
      elsif %w[oa-resolvable direct downloadable wayback].include?(route.status)
        acquire_remote_url(route, existing)
      elsif %w[manual reference-only].include?(route.status)
        record_terminal(route, existing, route.status)
      elsif %w[unresolved lost-candidate].include?(route.status)
        record_failure(route, existing, route.evidence)
      else
        record_failure(route, existing, "Acquisition adapter for #{route.status}/#{route.route} is not implemented")
      end
    rescue => e
      record_failure(route, existing, "Acquisition error: #{e.class}: #{e.message}")
    end

    def resumable?(slot)
      return false unless slot && slot["terminal_status"] == "acquired" && slot["object_id"]
      object = @store.read_object(slot["object_id"])
      return false unless object
      verify_object(object, slot["expectations"])["status"] == "passed"
    end

    def finalize(routes)
      @store.rebuild_registry!
      @store.slots.select { |slot| slot["terminal_status"] == "acquired" }.each do |slot|
        object = @store.read_object(slot["object_id"])
        verification = verify_object(object, slot["expectations"])
        raise ArgumentError, "acquired slot failed current verification: #{slot["artifact_id"]}" unless verification["status"] == "passed"
      end
      @store.write_coverage(routes)
    end

    private

    def acquire_local(route, existing)
      path = @store.expand_path(route.evidence_url.to_s)
      identity = "local:#{canonical_path(path)}"
      object = @store.find_object(identity)
      if object && verify_object(object)["status"] == "passed"
        verification = verify_object(object, expectations_for(route, path))
        if verification["status"] == "passed"
          return link_object(route, object, existing, {"verification" => verification})
        end
        return record_failure(route, existing, "Shared object does not satisfy slot expectations", object: object, verification_details: verification)
      end

      verifier = (route.route == "local-directory") ? @directory_verifier : @file_verifier
      verification = verifier.verify(path, expectations_for(route, path))
      attempt = {
        "method" => "VERIFY",
        "at" => now,
        "path" => @store.record_path(path),
        "status" => verification["status"],
        "checks" => verification["checks"]
      }
      unless verification["size"]
        return record_failure(route, existing, "Local artifact is missing: #{path}", attempts: [attempt])
      end
      object ||= new_object_identity(route, identity)
      object = build_object(object, route, identity, path, verification)
      @store.write_object(object)
      if verification["status"] == "passed"
        link_object(route, object, existing, {"attempts" => [attempt], "fetched_at" => now, "verification" => verification})
      else
        record_failure(route, existing, "Local artifact failed verification", object: object, attempts: [attempt], verification_details: verification)
      end
    end

    def acquire_attachment(route, existing)
      raise ArgumentError, "stored-PDF route lacks attachment key" unless Data.present?(route.attachment_key)
      raise ArgumentError, "no Zotero attachment fetcher configured" unless @attachment_fetcher
      acquire_remote(route, existing,
        identity: "zotero:attachment:#{route.attachment_key}", fetcher: @attachment_fetcher, source: route.attachment_key)
    end

    def acquire_repository(route, existing)
      url = route.evidence_url.to_s
      raise ArgumentError, "clonable route lacks a repository URL" if url.empty?
      identity = "git:#{canonical_url(url)}"
      object = @store.find_object(identity)
      if object && verify_object(object)["status"] == "passed"
        verification = verify_object(object, expectations_for(route, @store.expand_path(object.fetch("path"))))
        if verification["status"] == "passed"
          return link_object(route, object, existing, {"verification" => verification})
        end
        return record_failure(route, existing, "Existing repository does not satisfy slot expectations", object: object, verification_details: verification)
      end

      Dir.mktmpdir("git-clone-", @store.root) do |temporary|
        destination = File.join(temporary, "repository")
        metadata = @git_fetcher.clone(url, destination)
        unless metadata["success"]
          return record_failure(route, existing, "Clone failed: #{metadata["error"]}", object: object,
            attempts: metadata.fetch("attempts", []), verification_details: {"kind" => "repository", "checks" => []})
        end
        verification = @repository_verifier.verify(destination, expectations_for(route, destination).merge("remote_url" => url))
        object ||= new_object_identity(route, identity)
        payload = File.join(@store.object_directory(object["object_id"]), "repository")
        FileUtils.rm_rf(payload)
        FileUtils.mkdir_p(File.dirname(payload))
        FileUtils.mv(destination, payload)
        object = build_object(object, route, identity, payload, verification, clone_status: metadata.fetch("clone_status"))
        @store.write_object(object)
        if verification["status"] == "passed"
          return link_object(route, object, existing, metadata.merge("verification" => verification))
        end
        return record_failure(route, existing, "Cloned repository failed verification", object: object,
          attempts: metadata.fetch("attempts", []), verification_details: verification)
      end
    end

    def acquire_remote_url(route, existing)
      url = route.evidence_url.to_s
      raise ArgumentError, "#{route.status} route lacks a retrieval URL" if url.empty?
      local_path = Data.stringify(route.expectations)["local_path"]
      if %w[direct downloadable wayback].include?(route.status) && Data.present?(local_path)
        fallback = route.dup
        fallback.source_url = url
        fallback.evidence_url = local_path
        fallback.route = "local-file"
        return acquire_local(fallback, existing)
      end
      acquire_remote(route, existing, identity: "url:#{canonical_url(url)}", fetcher: @remote_fetcher, source: url)
    end

    def acquire_remote(route, existing, identity:, fetcher:, source:)
      object = @store.find_object(identity)
      if object && verify_attachment_integrity(object)["status"] == "passed"
        path = @store.expand_path(object.fetch("path"))
        verification = verify_object(object, expectations_for(route, path))
        if verification["status"] == "passed"
          return link_object(route, object, existing, {"verification" => verification})
        end
        return record_failure(route, existing, "Existing object does not satisfy slot expectations", object: object, verification_details: verification)
      end

      Tempfile.create(["remote-artifact", ".download"], @store.root) do |temporary|
        temporary.binmode
        temporary.close
        metadata = fetcher.fetch(source, temporary.path)
        if metadata["success"] == false
          reason = metadata["error"] || "HTTP #{metadata["http_status"]}"
          return record_failure(route, existing, "Download failed: #{reason}", object: object,
            attempts: metadata.fetch("attempts", []), verification_details: {"kind" => "file", "checks" => []})
        end
        verification = @file_verifier.verify(temporary.path, expectations_for(route, temporary.path))
        duplicate = @store.find_object_by_sha256(verification["sha256"])
        duplicate = nil if object && duplicate && duplicate["object_id"] == object["object_id"]
        if duplicate && verify_attachment_integrity(duplicate)["status"] == "passed"
          path = @store.expand_path(duplicate.fetch("path"))
          duplicate_verification = verify_object(duplicate, expectations_for(route, path))
          unless duplicate_verification["status"] == "passed"
            return record_failure(route, existing, "Deduplicated object does not satisfy slot expectations", object: duplicate,
              attempts: metadata.fetch("attempts", []), verification_details: duplicate_verification)
          end
          duplicate["identities"] = (duplicate["identities"] + [identity]).uniq
          return link_object(route, duplicate, existing, metadata.merge("verification" => duplicate_verification))
        end

        object = persist_attachment_object(object, route, identity, temporary.path, verification)
        unless verification["status"] == "passed"
          return record_failure(route, existing, "Downloaded object failed verification", object: object,
            attempts: metadata.fetch("attempts", []), verification_details: verification)
        end
        return link_object(route, object, existing, metadata)
      end
    end

    def persist_attachment_object(object, route, identity, source, verification)
      object ||= new_object_identity(route, identity)
      extension = case verification["media_type"]
      when "text/html"
        ".html"
      when "application/pdf"
        ".pdf"
      else
        ".bin"
      end
      payload = File.join(@store.object_directory(object["object_id"]), "content#{extension}")
      FileUtils.mkdir_p(File.dirname(payload))
      FileUtils.mv(source, payload)
      object = build_object(object, route, identity, payload, verification)
      @store.write_object(object)
      object
    end

    def verify_attachment_integrity(object)
      expectations = Data.stringify(object["expectations"]).reject do |key, _|
        %w[title ocr_markers ocr_pages html_markers anchor_count content_review].include?(key)
      end
      %w[size sha256 md5].each { |field| expectations[field] = object[field] if object[field] }
      @file_verifier.verify(@store.expand_path(object.fetch("path")), expectations)
    end

    def canonical_url(url)
      uri = URI.parse(url)
      uri.scheme = uri.scheme.to_s.downcase
      uri.host = uri.host.to_s.downcase
      uri.fragment = nil
      HttpDownloader.sanitize_url(uri.to_s)
    rescue URI::InvalidURIError
      HttpDownloader.sanitize_url(url)
    end

    def new_object_identity(route, identity)
      prefix = if route.route == "zotero-stored-pdf"
        "zotero-attachment-#{route.attachment_key.downcase}"
      elsif identity.start_with?("url:")
        "url-#{Digest::SHA256.hexdigest(identity)[0, 16]}"
      elsif identity.start_with?("git:")
        "git-#{Digest::SHA256.hexdigest(identity)[0, 16]}"
      else
        "local-#{Digest::SHA256.hexdigest(identity)[0, 16]}"
      end
      kind = if identity.start_with?("git:")
        "repository"
      elsif route.route == "local-directory"
        "directory"
      else
        "file"
      end
      {
        "object_id" => prefix,
        "kind" => kind,
        "identities" => [identity],
        "slot_ids" => [],
        "slot_manifests" => [],
        "provenance" => [],
        "created_at" => now
      }
    end

    def build_object(object, route, identity, path, verification, extra = {})
      expectations = expectations_for(route, path)
      media_type = if object["kind"] == "file"
        verification["media_type"] || expectations["media_type"] || ((File.extname(path).downcase == ".html") ? "text/html" : "application/pdf")
      end
      attributes = {
        object_id: object["object_id"],
        kind: object["kind"],
        path: @store.record_path(path),
        identities: object.fetch("identities", [identity]),
        media_type: media_type,
        expectations: expectations,
        verification: verification,
        provenance: object.fetch("provenance", []),
        slot_ids: object.fetch("slot_ids", []),
        slot_manifests: object.fetch("slot_manifests", []),
        created_at: object["created_at"] || now,
        updated_at: now
      }
      Manifest.object(attributes.merge(extra))
    end

    def link_object(route, object, existing, metadata)
      slot_path = Pathname.new(@store.slot_path(route.artifact_id)).relative_path_from(Pathname.new(@store.root)).to_s
      object["slot_ids"] = (object.fetch("slot_ids", []) + [route.artifact_id]).uniq.sort
      object["slot_manifests"] = (object.fetch("slot_manifests", []) + [slot_path]).uniq.sort
      provenance = {
        "artifact_id" => route.artifact_id,
        "route" => route.route,
        "evidence" => route.evidence,
        "source_urls" => metadata["source_urls"] || [route.source_url, route.evidence_url].compact,
        "fetched_at" => metadata["fetched_at"] || now
      }
      object["provenance"] = Array(object["provenance"]).reject { |entry| entry["artifact_id"] == route.artifact_id } + [provenance]
      object["updated_at"] = now
      verification = (metadata["verification"] || object.fetch("verification")).merge("evidence" => "Physical object integrity and expected content verified")
      object["verification"] = verification
      @store.write_object(object)
      write_slot(route, existing, "acquired", object: object, metadata: metadata, verification: verification)
      ProcessResult.new(artifact_id: route.artifact_id, action: "acquired", terminal_status: "acquired", object_id: object["object_id"])
    end

    def record_terminal(route, existing, status)
      verification = {"status" => "recorded", "evidence" => route.evidence}
      write_slot(route, existing, status, verification: verification)
      ProcessResult.new(artifact_id: route.artifact_id, action: "recorded", terminal_status: status)
    end

    def record_failure(route, existing, reason, object: nil, attempts: [], verification_details: nil)
      verification = Data.stringify(verification_details).merge("status" => "failed", "evidence" => reason.to_s)
      if object
        slot_path = Pathname.new(@store.slot_path(route.artifact_id)).relative_path_from(Pathname.new(@store.root)).to_s
        object["slot_ids"] = (object.fetch("slot_ids", []) + [route.artifact_id]).uniq.sort
        object["slot_manifests"] = (object.fetch("slot_manifests", []) + [slot_path]).uniq.sort
        object["verification"] = verification if verification_details && object.dig("verification", "status") == "failed"
        @store.write_object(object)
      end
      write_slot(route, existing, "failed", object: object, verification: verification, metadata: {"attempts" => attempts})
      ProcessResult.new(artifact_id: route.artifact_id, action: "failed", terminal_status: "failed",
        object_id: object && object["object_id"], error: reason.to_s)
    end

    def write_slot(route, existing, status, verification:, object: nil, metadata: {})
      previous_attempts = existing ? existing.fetch("attempts", []) : []
      previous_failed_object_id = (existing && existing["terminal_status"] == "failed") ? existing["object_id"] : nil
      slot = Manifest.slot(
        artifact_id: route.artifact_id,
        audit_unit: route.audit_unit,
        requirement: route.requirement,
        route: route.route,
        terminal_status: status,
        object_id: object && object["object_id"],
        source_urls: metadata["source_urls"] || [route.source_url, route.evidence_url].compact,
        final_url: metadata["final_url"],
        provenance: {
          "phase2_status" => route.status,
          "phase2_evidence" => route.evidence,
          "attachment_key" => route.attachment_key,
          "item_title" => route.item_title
        },
        version_edition: Data.stringify(route.expectations)["version_edition"],
        fetched_at: metadata["fetched_at"] || now,
        attempts: previous_attempts + metadata.fetch("attempts", []),
        verification: verification,
        qualifications: Array(Data.stringify(route.expectations)["qualifications"]),
        expectations: Data.stringify(route.expectations)
      )
      @store.write_slot(slot)
      prune_replaced_failed_object(previous_failed_object_id, slot["object_id"])
      slot
    end

    def prune_replaced_failed_object(previous_object_id, current_object_id)
      return if previous_object_id.nil? || previous_object_id == current_object_id
      return if @store.slots.any? { |slot| slot["object_id"] == previous_object_id }

      FileUtils.rm_rf(@store.object_directory(previous_object_id))
    end

    def verify_object(object, slot_expectations = nil)
      expectations = Data.stringify(object["expectations"]).merge(Data.stringify(slot_expectations))
      case object["kind"]
      when "repository"
        expectations = expectations.merge("remote_url" => object["remote_url"], "head" => object["head"])
        @repository_verifier.verify(@store.expand_path(object.fetch("path")), expectations)
      when "directory"
        expectations["inventory_sha256"] = object["inventory_sha256"]
        @directory_verifier.verify(@store.expand_path(object.fetch("path")), expectations)
      else
        %w[size sha256 md5].each { |field| expectations[field] = object[field] if object[field] }
        @file_verifier.verify(@store.expand_path(object.fetch("path")), expectations)
      end
    end

    def expectations_for(route, path)
      expectations = Data.stringify(route.expectations)
      return expectations if %w[local-directory git-host].include?(route.route)

      unless %w[oa-resolvable direct downloadable wayback].include?(route.status)
        expectations["media_type"] ||= (File.extname(path).downcase == ".pdf") ? "application/pdf" : "text/html"
      end
      expectations["title"] ||= route.item_title if route.item_title && !expectations.key?("ocr_markers")
      expectations
    end

    def canonical_path(path)
      File.realpath(path)
    rescue Errno::ENOENT
      File.expand_path(path)
    end

    def now
      @clock.call.utc.iso8601
    end
  end
end
