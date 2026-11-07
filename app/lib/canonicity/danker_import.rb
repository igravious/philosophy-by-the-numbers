require "digest"
require "set"

module Canonicity
  class DankerImport
    attr_reader :artifact_checksum

    def initialize(file_path, subject_type: "Philosopher", source_version: nil, import_identity: nil)
      @file_path = file_path
      @subject_type = subject_type
      @source_version = source_version || File.basename(File.dirname(file_path))
      @import_identity = import_identity
    end

    def call
      scores = validated_scores
      MetricOperationLock.synchronize do
        subject_class.transaction do
          subject_class.order(:id).find_each do |shadow|
            new_value = scores[shadow.entity_id]
            old_value = shadow.danker
            shadow.update!(danker: new_value)
            SourceEvent.create!(
              source_name: "danker",
              source_version: @source_version,
              import_identity: import_identity,
              artifact_identity: File.basename(@file_path),
              artifact_checksum: artifact_checksum,
              shadow_id: shadow.id,
              shadow_type: @subject_type,
              entity_id: shadow.entity_id,
              attribute_name: "danker",
              old_value: old_value,
              new_value: new_value,
              provenance: {"file_row_count" => @validated_row_count},
              imported_at: Time.current
            )
          end
        end
      end
      import_identity
    end

    private

    def subject_class
      @subject_class ||= @subject_type.constantize
    rescue NameError
      raise ImportError, "Unknown subject type: #{@subject_type}"
    end

    def validated_scores
      raise ImportError, "Danker file is missing: #{@file_path}" unless File.file?(@file_path)

      required_entity_ids = subject_class.where.not(entity_id: nil).distinct.pluck(:entity_id).to_set
      scores = {}
      checksum = Digest::SHA256.new
      previous_entity = nil
      @validated_row_count = 0

      File.foreach(@file_path).with_index(1) do |line, line_number|
        checksum.update(line)
        next if line.strip.empty?

        entity, score = line.strip.split(/[\t,]/, -1)
        unless entity =~ /\AQ\d+\z/ && score
          raise ImportError, "Invalid Danker row #{line_number}: #{line.strip}"
        end
        if entity == previous_entity
          raise ImportError, "Duplicate Danker entity on row #{line_number}: #{entity}"
        end
        if previous_entity && entity < previous_entity
          raise ImportError, "Danker entities are not sorted on row #{line_number}: #{entity}"
        end

        begin
          value = Float(score)
        rescue ArgumentError
          raise ImportError, "Invalid Danker score on row #{line_number}: #{score}"
        end
        unless value.finite? && value >= 0.0
          raise ImportError, "Invalid Danker score on row #{line_number}: #{score}"
        end

        entity_id = entity[1..].to_i
        scores[entity_id] = value if required_entity_ids.include?(entity_id)
        previous_entity = entity
        @validated_row_count += 1
      end
      raise ImportError, "Danker file contains no scores" if @validated_row_count.zero?

      @artifact_checksum = checksum.hexdigest
      scores
    end

    def import_identity
      @import_identity ||= "danker-#{artifact_checksum}"
    end
  end
end
