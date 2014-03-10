class AddIndexToRefid < ActiveRecord::Migration
  def self.up
   add_index :ref_ids, :value, :unique => true
   add_index :ref_ids, :trigesimal_value, :unique => true
  end

  def self.down
   remove_index :ref_ids, :column => :value
   remove_index :ref_ids, :column => :trigesimal_value
  end
end
