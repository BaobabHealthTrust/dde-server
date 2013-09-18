class CreateFootprintTrackers < ActiveRecord::Migration
  def self.up
    create_table :footprint_trackers do |t|
      t.datetime :start_datetime
      t.datetime :end_datetime

      t.timestamps
    end
  end

  def self.down
    drop_table :footprint_trackers
  end
end
