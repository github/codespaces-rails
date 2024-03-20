class AddPreReqToPartition < ActiveRecord::Migration[7.1]
  def change
    add_column :partitions, :prerequisite, :boolean
  end
end
