class AddDecimalNumToNationalPatientIdentifiers < ActiveRecord::Migration
  def self.up
    
    change_table :national_patient_identifiers do |n|
      n.integer :decimal_num, :null => true, :after => :value
    end
    
    add_index :national_patient_identifiers, :decimal_num, :unique => true
    
    add_column :national_patient_identifiers,:voided,:integer,:null => false,:default => 0,:after => :updated_at
    
    NationalPatientIdentifier.select('id, value, decimal_num').each do |npid|
      id = NationalPatientId.to_decimal npid.value, 30
      num = id / 10
      
      npid.decimal_num = num
      npid.save rescue nil
    end
    
    remove_column :national_patient_identifiers,:voided
    
  end

  def self.down
    remove_index  :national_patient_identifiers, :decimal_num
    remove_column :national_patient_identifiers, :decimal_num
  end
end
