class AddRemoteVersionNumberToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :remote_version_number, :string
  end

  def self.down
    remove_column :people, :remote_version_number
  end
end
