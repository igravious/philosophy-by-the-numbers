class UseTwoDecimalPhilosopherBitsetWeights < ActiveRecord::Migration
  TWO_DECIMAL_WEIGHTS = {
    "inphobool" => 0.10,
    "borchert" => 0.17,
    "internet" => 0.03,
    "cambridge" => 0.13,
    "kemerling" => 0.07,
    "populate" => 0.01,
    "oxford3" => 0.13,
    "routledge" => 0.17,
    "dbpedia" => 0.01,
    "stanford" => 0.10,
    "all_bonus" => 0.08
  }.freeze

  PREVIOUS_WEIGHTS = {
    "inphobool" => 0.099338,
    "borchert" => 0.165563,
    "internet" => 0.033113,
    "cambridge" => 0.132450,
    "kemerling" => 0.066225,
    "populate" => 0.013245,
    "oxford3" => 0.132450,
    "routledge" => 0.165563,
    "dbpedia" => 0.006623,
    "stanford" => 0.099338,
    "all_bonus" => 0.086092
  }.freeze

  def up
    update_weights(TWO_DECIMAL_WEIGHTS)
  end

  def down
    update_weights(PREVIOUS_WEIGHTS)
  end

  private

  def update_weights(weights)
    weights.each do |source_name, weight_value|
      CanonicityWeights.where(algorithm_version: "2.0", source_name: source_name).update_all(
        weight_value: weight_value,
        updated_at: Time.current
      )
    end
  end
end
