class CreateNationalIdSites < ActiveRecord::Migration
  def self.up
    create_table :national_id_sites do |t|
      t.string :national_id, :null => false
      t.integer :site_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :national_id_sites
  end
end
