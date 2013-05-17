class AddNotifyToUsers < ActiveRecord::Migration
  def self.up
		add_column :users,:notify,:boolean,:default => false,:after => :disabled
  end

  def self.down
		remove_column :users,:notify
  end
end
