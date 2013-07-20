class Footprint < ActiveRecord::Base
  def self.up
    create_table :footprint do |t|
      t.string :value
      t.integer :site_id
      t.integer :app_location_id
      t.datetime :interaction_datetime

      t.timestamps
    end
  end

  def self.down
    drop_table :footprint
  end
end
