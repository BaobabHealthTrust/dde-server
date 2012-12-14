class CreateSyncs < ActiveRecord::Migration
  def self.up
    create_table :syncs do |t|
      t.string :sync_site_id, :null => false
      t.datetime :created_date, :null => false
      t.datetime :updated_date, :null => false

      t.timestamps 
    end
  end

  def self.down
    drop_table :syncs
  end
end
