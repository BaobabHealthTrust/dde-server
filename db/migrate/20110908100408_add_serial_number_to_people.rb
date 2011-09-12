class AddSerialNumberToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :version_number,  :string, :default => 0
    add_column :people, :creator_id,      :string
    add_column :people, :creator_site_id, :string
  end

  def self.down
    remove_column :people, :version_number
    remove_column :people, :creator_id
    remove_column :people, :creator_site_id
  end
end
