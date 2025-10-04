class AddDankerToShadow < ActiveRecord::Migration

	# Compute PageRank on >3 billion Wikipedia links on off-the-shelf hardware.
	#
	# https://github.com/athalhammer/danker

  def change
    add_column :shadows, :danker, :float
  end
end
