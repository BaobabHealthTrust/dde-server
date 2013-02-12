class AddLastPersonIdColumn < ActiveRecord::Migration
  def self.up
    #add_column :syncs, :last_person_id, :integer,:null => false, :after => :sync_site_id
  end

  def self.down
    #remove_column :syncs, :last_person_id
  end
end
