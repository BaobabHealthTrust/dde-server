class CreateNpidAutoGenerations < ActiveRecord::Migration
  def self.up
    create_table :npid_auto_generations do |t|
      t.integer :site_id
      t.integer :threshold

      t.timestamps
    end
  end

  def self.down
    drop_table :npid_auto_generations
  end
end
