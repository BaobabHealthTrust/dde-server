class RenameSyncsToProxySyncs < ActiveRecord::Migration
  def self.up
  	rename_table :syncs, :proxy_syncs
  	rename_column :proxy_syncs, :created_date, :start_date
  	rename_column :proxy_syncs, :updated_date, :end_date
  end

  def self.down
  	rename_table :proxy_syncs, :syncs 
  	rename_column :syncs, :start_date, :created_date 
  	rename_column :syncs, :end_date, :updated_date
  end
end
