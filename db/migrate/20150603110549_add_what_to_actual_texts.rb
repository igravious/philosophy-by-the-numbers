class AddWhatToActualTexts < ActiveRecord::Migration
  def change
    add_column :actual_texts, :what, :string
  end
end
