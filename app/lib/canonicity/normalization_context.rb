module Canonicity
  class NormalizationContext
    def self.for_records(records, subject_type)
      normalization_records = records.select(&:normalization?)
      mentions = normalization_records.map { |record| record.input_payload["mention"] }.compact.map(&:to_f)
      ranks = normalization_records.map { |record| record.input_payload["danker"] }.compact.map(&:to_f)
      ranks = ranks.reject(&:zero?) if subject_type == "Work"
      {
        "max_mention" => mentions.max || 1.0,
        "max_rank" => ranks.max || 1.0,
        "min_rank" => (ranks.min || 0.1) / 2.0
      }
    end
  end
end
