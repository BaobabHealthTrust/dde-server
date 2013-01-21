class CreateMasterSyncDetails < ActiveRecord::Migration
  def self.up
    create_table :master_sync_details do |t|
      t.integer :master_sync_id, :null => false
      t.datetime :start_date, :null => false
      t.datetime :end_date
    end
  end

  def self.down
    drop_table :master_sync_details
  end
end
