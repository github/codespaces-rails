class AddApplicationIdToDeployment < ActiveRecord::Migration[7.1]
  def change
    add_column :deployments, :application_id, :integer
  end
end
