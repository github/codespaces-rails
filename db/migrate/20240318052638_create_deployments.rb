# typed: false
class CreateDeployments < ActiveRecord::Migration[7.1]
  def change
    create_table :deployments do |t|
      t.integer :state
      t.integer :run_result
      t.string :strategy

      t.timestamps
    end
  end
end
