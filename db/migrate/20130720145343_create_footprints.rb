class CreateFootprints < ActiveRecord::Migration
  def self.up
    create_table :footprints do |t|
      t.string :value
      t.integer :site_id
      t.integer :app_location_id

      t.timestamps
    end
  end

  def self.down
    drop_table :footprints
  end
end
