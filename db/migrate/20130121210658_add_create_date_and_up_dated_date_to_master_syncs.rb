class AddCreateDateAndUpDatedDateToMasterSyncs < ActiveRecord::Migration
  def self.up
   add_column :master_syncs,:created_date,:datetime,:null => false,:after => :site_code
   add_column :master_syncs,:updated_date,:datetime,:after => :created_date
  end

  def self.down
   add_column :master_syncs,:created_date
   add_column :master_syncs,:updated_date
  end
end
