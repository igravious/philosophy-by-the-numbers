require "set"

module Canonicity
  class WorkFlagImport
    attr_reader :artifact_checksum

    FLAGS = {"cambridge" => 2, "borchert" => 3, "routledge" => 4}.freeze

    def initialize(file_path, source_version: nil, import_identity: nil)
      @file_path = file_path
      @source_version = source_version || File.basename(File.dirname(file_path))
      @import_identity = import_identity
    end

    def call
      records = validated_records
      MetricOperationLock.synchronize do
        ::Work.transaction do
          records.each do |work, flags|
            old_flags = FLAGS.keys.each_with_object({}) { |flag, result| result[flag] = work.public_send(flag) }
            work.update!(flags)
            FLAGS.each_key do |flag|
              SourceEvent.create!(
                source_name: "reference_work_flags",
                source_version: @source_version,
                import_identity: import_identity,
                artifact_identity: File.basename(@file_path),
                artifact_checksum: artifact_checksum,
                shadow_id: work.id,
                shadow_type: "Work",
                entity_id: work.entity_id,
                attribute_name: flag,
                old_value: old_flags[flag],
                new_value: flags[flag],
                provenance: {"file" => File.basename(@file_path)},
                imported_at: Time.current
              )
            end
          end
        end
      end
      import_identity
    end

    private

    def validated_records
      raise ImportError, "Work flag file is missing: #{@file_path}" unless File.file?(@file_path)

      contents = File.read(@file_path)
      @artifact_checksum = Digest::SHA256.hexdigest(contents)
      rows = JSON.parse(contents)
      raise ImportError, "Work flag file must contain a JSON array" unless rows.is_a?(Array)

      seen_entity_ids = Set.new
      rows.map.with_index(1) do |row, index|
        unless row.is_a?(Array) && row.length >= 5 && row[0].is_a?(Integer)
          raise ImportError, "Invalid Work flag row #{index}"
        end
        raise ImportError, "Duplicate Work Q#{row[0]} on row #{index}" if seen_entity_ids.include?(row[0])

        seen_entity_ids.add(row[0])
        work = ::Work.find_by(entity_id: row[0])
        raise ImportError, "Work Q#{row[0]} on row #{index} is missing" unless work

        flags = FLAGS.each_with_object({}) do |(flag, column), result|
          value = row[column]
          raise ImportError, "Invalid #{flag} value on row #{index}" unless ["y", "n"].include?(value)

          result[flag] = value == "y"
        end
        [work, flags]
      end
    rescue JSON::ParserError => error
      raise ImportError, "Invalid Work flag JSON: #{error.message}"
    end

    def import_identity
      @import_identity ||= "work-flags-#{artifact_checksum}"
    end
  end
end
