class CreateMasterSyncTraditionalAuthorities < ActiveRecord::Migration
  def self.up
    create_table :master_sync_traditional_authorities do |t|
      t.string :district ,:null => false
      t.string :traditional_authority ,:null => false
      t.datetime :start_datetime ,:null => false
      t.datetime :end_datetime
      t.boolean :transaction_completed, :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :master_sync_traditional_authorities
  end
end
