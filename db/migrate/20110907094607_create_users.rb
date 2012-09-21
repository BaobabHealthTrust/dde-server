class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :password_hash
      t.string :site
      t.string :email
      t.string :description
      t.boolean :disabled, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
