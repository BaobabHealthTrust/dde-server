class AddIndexToValueFields < ActiveRecord::Migration
  def self.up
  	add_index :national_patient_identifiers, :value
    add_index :legacy_national_ids, :value
  end

  def self.down
  	remove_index :national_patient_identifiers, :column => :value
  	remove_index :legacy_national_ids, :column => :value
  end
end
