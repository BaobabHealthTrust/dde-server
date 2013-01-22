class ChangeEndDateToNull < ActiveRecord::Migration
  def self.up
  	change_column :proxy_syncs, :end_date, :datetime, :null => true
  	remove_column :proxy_syncs, :sync_site_id
  	remove_column :proxy_syncs, :last_person_id
  end

  def self.down
  	change_column :proxy_syncs, :end_date, :datetime, :null => false
  end
end
