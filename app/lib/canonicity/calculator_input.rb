module Canonicity
  class CalculatorInput
    def self.philosopher(record)
      payload = record.input_payload
      sources = payload.fetch("sources")
      {
        mention: payload.fetch("mention"),
        danker: payload.fetch("danker"),
        capacities: payload.fetch("capacity_ids"),
        sources: Canonicity::Philosopher::V2::SOURCES.each_with_object({}) do |source, result|
          result[source.to_sym] = sources.fetch(source)
        end
      }
    end

    def self.work(record)
      payload = record.input_payload
      inputs = {
        mention: payload.fetch("mention"),
        danker: payload.fetch("danker"),
        philrecord: payload.fetch("philrecord"),
        philtopic: payload.fetch("philtopic"),
        genre: payload.fetch("genre")
      }
      Canonicity::Work::V2::ENCYCLOPEDIA_SOURCES.each do |source|
        inputs[source.to_sym] = payload.fetch(source)
      end
      inputs[:author_measures] = payload.fetch("author_measures")
      inputs
    end

    def self.work_dependencies(record)
      {author_measures: record.input_payload.fetch("author_measures")}
    end

    def self.normalization_context(dataset)
      context = dataset.normalization_context
      {
        max_mention: context.fetch("max_mention"),
        max_rank: context.fetch("max_rank"),
        min_rank: context.fetch("min_rank")
      }
    end
  end
end
