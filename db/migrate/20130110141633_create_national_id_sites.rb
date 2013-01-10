class CreateNationalIdSites < ActiveRecord::Migration
  def self.up
    create_table :national_id_sites do |t|
      t.string :national_id
      t.integer :site_id

      t.timestamps
    end
  end

  def self.down
    drop_table :national_id_sites
  end
end
