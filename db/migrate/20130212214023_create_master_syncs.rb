class CreateMasterSyncs < ActiveRecord::Migration
  def self.up
    create_table :master_syncs do |t|
      t.string :site_code ,:null => false
      t.date :created_date
      t.date :updated_date

      t.timestamps
    end
  end

  def self.down
    drop_table :master_syncs
  end
end
