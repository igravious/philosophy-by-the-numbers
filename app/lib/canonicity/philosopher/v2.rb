module Canonicity
  module Philosopher
    class V2
      SOURCES = %w[inphobool borchert internet cambridge kemerling populate oxford3 routledge dbpedia stanford].freeze
      SUPPRESSED_CAPACITY_IDS = [413, 41_217, 269_323].freeze

      def self.call(inputs:, weights:, normalization_context:, dependency_inputs: {})
        new(inputs, weights, normalization_context).call
      end

      def initialize(inputs, weights, normalization_context)
        @inputs = inputs
        @weights = weights
        @normalization_context = normalization_context
      end

      def call
        source_contributions = calculate_source_contributions
        total_source_weight = source_contributions.values.sum
        max_mention = @normalization_context[:max_mention].to_f
        max_rank = @normalization_context[:max_rank].to_f
        mention = effective_mention
        rank = @inputs[:danker].nil? ? @normalization_context[:min_rank].to_f : @inputs[:danker].to_f

        normalized_measure = if max_mention.zero? || max_rank.zero? || total_source_weight.zero?
          0.0
        else
          Canonicity::Normalization.product(
            mention: mention / max_mention,
            rank: rank / max_rank,
            source_coverage: total_source_weight
          )
        end

        {
          normalized_measure: normalized_measure,
          measure: normalized_measure * 10_000_000,
          calculation_context: {
            source_contributions: source_contributions,
            total_source_weight: total_source_weight,
            mention: mention,
            rank: rank,
            max_mention: max_mention,
            max_rank: max_rank,
            min_rank: @normalization_context[:min_rank].to_f
          }
        }
      end

      private

      def calculate_source_contributions
        contributions = SOURCES.each_with_object({}) do |source, result|
          result[source] = @inputs[:sources][source.to_sym] ? @weights[source].to_f : 0.0
        end
        contributions["all_bonus"] = contributions.values.sum.positive? ? @weights["all_bonus"].to_f : 0.0
        contributions
      end

      def effective_mention
        mention = @inputs[:mention]
        capacities = @inputs[:capacities] || []
        return 0.0 if mention.nil? || mention.zero?
        return 0.0 if (capacities & SUPPRESSED_CAPACITY_IDS).length > 1

        mention.to_f
      end
    end
  end
end
