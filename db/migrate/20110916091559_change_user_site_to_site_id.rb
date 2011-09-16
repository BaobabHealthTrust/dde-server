class ChangeUserSiteToSiteId < ActiveRecord::Migration
  def self.up
    add_column :users, :site_id, :integer
    remove_column :users, :site
  end

  def self.down
    remove_column :users, :site_id
    add_column :users, :site, :string
  end
end
