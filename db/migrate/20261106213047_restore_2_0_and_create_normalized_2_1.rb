class Restore20AndCreateNormalized21 < ActiveRecord::Migration
  ORIGINAL_WEIGHTS = {
    "inphobool" => 0.15,
    "borchert" => 0.25,
    "internet" => 0.05,
    "cambridge" => 0.20,
    "kemerling" => 0.10,
    "populate" => 0.02,
    "oxford3" => 0.20,
    "routledge" => 0.25,
    "dbpedia" => 0.01,
    "stanford" => 0.15,
    "all_bonus" => 0.13
  }.freeze

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

  def up
    normalized_rows = CanonicityWeights.where(algorithm_version: "2.0").to_a
    normalized_rows.each do |row|
      weight = CanonicityWeights.find_or_initialize_by(algorithm_version: "2.1", source_name: row.source_name)
      weight.assign_attributes(
        weight_value: row.weight_value,
        description: row.description,
        active: row.active
      )
      weight.save!
    end
    ORIGINAL_WEIGHTS.each do |source_name, weight_value|
      CanonicityWeights.where(algorithm_version: "2.0", source_name: source_name).update_all(
        weight_value: weight_value,
        updated_at: Time.current
      )
    end
    CanonicitySignal.where(algorithm_version: "2.0").find_each do |signal|
      CanonicitySignal.create!(
        algorithm_version: "2.1",
        name: signal.name,
        description: signal.description,
        source: signal.source,
        subject_to_change: signal.subject_to_change,
        used_in_formula: signal.used_in_formula,
        active: signal.active
      )
    end
  end

  def down
    CanonicityWeights.where(algorithm_version: "2.1").delete_all
    CanonicitySignal.where(algorithm_version: "2.1").delete_all
    TWO_DECIMAL_WEIGHTS.each do |source_name, weight_value|
      CanonicityWeights.where(algorithm_version: "2.0", source_name: source_name).update_all(
        weight_value: weight_value,
        updated_at: Time.current
      )
    end
  end
end
