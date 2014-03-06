class AddTrigesimalValueToRefIds < ActiveRecord::Migration
  def self.up
    add_column :ref_ids, :trigesimal_value, :string, :size => 10, :default => nil, :after => :value
    add_column :ref_ids, :assigned, :boolean, :default => false, :after => :trigesimal_value
  	add_index :ref_ids, :value, :unique => true
    add_index :ref_ids, :trigesimal_value, :unique => true
  end

  def self.down
    remove_index :ref_ids, :column => :value
    remove_index :ref_ids, :column => :trigesimal_value
    remove_column :ref_ids, :trigesimal_value
    remove_column :ref_ids, :assigned
  end

end
