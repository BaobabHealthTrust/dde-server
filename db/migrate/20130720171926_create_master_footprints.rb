class CreateMasterFootprints < ActiveRecord::Migration
  def self.up
    create_table :master_footprints do |t|
      t.string :value
      t.integer :site_id
      t.integer :app_location_id
      t.datetime :interaction_datetime

      t.timestamps
    end
  end

  def self.down
    drop_table :master_footprints
  end
end
