module Canonicity
  class DenseRank
    def self.for(measures)
      previous_measure = nil
      rank = 0
      measures.sort_by { |shadow_id, measure| [-measure.to_f, shadow_id] }.each_with_object({}) do |(shadow_id, measure), ranks|
        rank += 1 if previous_measure.nil? || measure != previous_measure
        ranks[shadow_id] = rank
        previous_measure = measure
      end
    end
  end
end
