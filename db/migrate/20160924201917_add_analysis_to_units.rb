class AddAnalysisToUnits < ActiveRecord::Migration
  def change
    add_column :units, :analysis, :string
  end
end
