# typed: false
class CreatePartitions < ActiveRecord::Migration[7.1]
  def change
    create_table :partitions do |t|
      t.integer :deployment_id
      t.integer :run_state

      t.timestamps
    end
  end
end
