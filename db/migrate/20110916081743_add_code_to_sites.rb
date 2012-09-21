class AddCodeToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :code, :string, :size => 5, :default => ''
  end

  def self.down
    remove_column :sites, :code
  end
end
