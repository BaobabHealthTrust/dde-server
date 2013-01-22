class ChangeEndDateToNull < ActiveRecord::Migration
  def self.up
  	change_column :proxy_syncs, :end_date, :datetime, :null => true
  end

  def self.down
  	change_column :proxy_syncs, :end_date, :datetime, :null => false
  end
end
