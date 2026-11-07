module Canonicity
  module Work
    class V2
      ENCYCLOPEDIA_SOURCES = %w[borchert cambridge routledge].freeze

      def self.call(inputs:, weights:, normalization_context:, dependency_inputs: {})
        new(inputs, weights, normalization_context, dependency_inputs).call
      end

      def initialize(inputs, weights, normalization_context, dependency_inputs)
        @inputs = inputs
        @weights = weights
        @normalization_context = normalization_context
        @dependency_inputs = dependency_inputs
      end

      def call
        max_mention = @normalization_context[:max_mention].to_f
        max_rank = @normalization_context[:max_rank].to_f
        return zero_result if max_mention.zero? || max_rank.zero?

        source_contributions = calculate_source_contributions
        sourcey = source_contributions.values.sum
        exists = author_adjustment(sourcey)
        sourcey = 0.1 if sourcey.zero?
        mention = (@inputs[:mention].nil? || @inputs[:mention].zero?) ? 0.5 : @inputs[:mention].to_f
        rank = @inputs[:danker].nil? ? @normalization_context[:min_rank].to_f : @inputs[:danker].to_f
        genre = @inputs[:genre] ? @weights["genre_philosophical"].to_f : @weights["genre_other"].to_f
        normalized_measure = Canonicity::Normalization.product(
          mention: mention / max_mention,
          rank: rank / max_rank,
          genre: genre,
          source_and_author: sourcey + exists
        )

        {
          normalized_measure: normalized_measure,
          measure: normalized_measure * 1_000_000,
          calculation_context: {
            source_contributions: source_contributions,
            sourcey: sourcey,
            exists: exists,
            mention: mention,
            rank: rank,
            genre: genre,
            max_mention: max_mention,
            max_rank: max_rank,
            min_rank: @normalization_context[:min_rank].to_f
          }
        }
      end

      private

      def calculate_source_contributions
        contributions = ENCYCLOPEDIA_SOURCES.each_with_object({}) do |source, result|
          result[source] = @inputs[source.to_sym] ? @weights[source].to_f : 0.0
        end
        encyclopedia_sum = contributions.values.sum
        contributions["all_bonus"] = encyclopedia_sum.positive? ? @weights["all_bonus"].to_f : 0.0
        contributions["philpapers"] = (@inputs[:philrecord] || @inputs[:philtopic]) ? @weights["philpapers"].to_f : 0.0
        contributions
      end

      def author_adjustment(sourcey)
        measures = @dependency_inputs[:author_measures] || []
        raise ArgumentError, "author measure is missing" if measures.any?(&:nil?)

        (measures.any? && measures.sum.zero?) ? -sourcey : 0.0
      end

      def zero_result
        {normalized_measure: 0.0, measure: 0.0, calculation_context: {}}
      end
    end
  end
end
