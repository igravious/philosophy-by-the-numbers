module Canonicity
  class Calculator
    IDENTITIES = {
      "philosopher-v2" => Canonicity::Philosopher::V2,
      "work-v2" => Canonicity::Work::V2
    }.freeze

    def self.call(identity, inputs:, weights:, normalization_context:, dependency_inputs: {})
      calculator = IDENTITIES.fetch(identity)
      calculator.call(
        inputs: inputs,
        weights: weights,
        normalization_context: normalization_context,
        dependency_inputs: dependency_inputs
      )
    end
  end
end
