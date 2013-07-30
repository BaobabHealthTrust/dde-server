class CreateFootprints < ActiveRecord::Migration
  def self.up
    create_table :footprints do |t|
      t.string :value
      t.string :application_name

      t.timestamps
    end
  end

  def self.down
    drop_table :footprints
  end
end
