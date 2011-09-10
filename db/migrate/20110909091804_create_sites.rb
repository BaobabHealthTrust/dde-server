class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.string :name
      t.string :annotations

      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
