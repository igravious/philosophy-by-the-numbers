module Canonicity
  class Normalization
    def self.product(components)
      normalized = components.inject(1.0) do |product, (name, value)|
        component = Float(value)
        unless component.finite? && component >= 0.0 && component <= 1.0
          raise NormalizationError, "#{name} must be between 0.0 and 1.0 inclusive (got #{value.inspect})"
        end
        product * component
      end
      unless normalized.finite? && normalized >= 0.0 && normalized <= 1.0
        raise NormalizationError, "normalized_measure must be between 0.0 and 1.0 inclusive (got #{normalized.inspect})"
      end
      normalized
    end
  end
end
