class MarkLegacyCanonicitySourcesInactive < ActiveRecord::Migration
  def up
    change_column :canonicity_weights, :weight_value, :decimal, precision: 8, scale: 6, null: true
    CanonicityWeights.where(algorithm_version: "2.0", source_name: ["oxford", "oxford2", "runes"]).update_all(
      weight_value: nil,
      active: false,
      updated_at: Time.current
    )
  end

  def down
    CanonicityWeights.where(algorithm_version: "2.0", source_name: "oxford").update_all(
      weight_value: 0.2,
      active: false,
      updated_at: Time.current
    )
    CanonicityWeights.where(algorithm_version: "2.0", source_name: ["oxford2", "runes"]).update_all(
      weight_value: 0.0,
      active: true,
      updated_at: Time.current
    )
    change_column :canonicity_weights, :weight_value, :decimal, precision: 8, scale: 6, null: false
  end
end
