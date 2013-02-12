class CreateProxySyncs < ActiveRecord::Migration
  def self.up
    create_table :proxy_syncs do |t|
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end

  def self.down
    drop_table :proxy_syncs
  end
end
