require "test_helper"

class CanonicityCalculatorInputTest < ActiveSupport::TestCase
  test "adapts a database-round-tripped Philosopher payload with required keys" do
    philosopher = create_test_philosopher(mention: 100, danker: nil, stanford: true)
    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher",
      selected_entity_ids: [philosopher.id],
      normalization_entity_ids: [philosopher.id]
    ).call
    record = dataset.metric_input_records.first.reload

    inputs = Canonicity::CalculatorInput.philosopher(record)
    normalization = Canonicity::CalculatorInput.normalization_context(dataset.reload)

    assert_equal 100, inputs[:mention]
    assert_nil inputs[:danker]
    assert_equal [], inputs[:capacities]
    assert inputs[:sources][:stanford]
    assert_equal 100.0, normalization[:max_mention]
  end

  test "Work adaptation fetches every required primitive and dependency" do
    payload = JSON.parse(JSON.generate({
      "mention" => 0,
      "danker" => nil,
      "borchert" => true,
      "cambridge" => false,
      "routledge" => true,
      "philrecord" => nil,
      "philtopic" => "topic",
      "genre" => true,
      "author_measures" => [0.0]
    }))
    record = MetricInputRecord.new(input_payload: payload)

    inputs = Canonicity::CalculatorInput.work(record)

    assert_equal 0, inputs[:mention]
    assert inputs[:borchert]
    assert_equal "topic", inputs[:philtopic]
    assert_equal [0.0], inputs[:author_measures]
    record.input_payload.delete("genre")
    assert_raises(KeyError) { Canonicity::CalculatorInput.work(record) }
  end
end
