class AddDecimalNumToNationalPatientIdentifiers < ActiveRecord::Migration
  def self.up
    change_table :national_patient_identifiers do |n|
      n.integer :decimal_num, :null => true, :after => :value
    end
    
    add_index :national_patient_identifiers, :decimal_num, :unique => true
    
    NationalPatientIdentifier.where('LENGTH(value) = 6').each do |npid|
      id = NationalPatientId.to_decimal npid.value, 30
      num = id / 10
      next if NationalPatientIdentifier.find_by_decimal_num num
      
      npid.decimal_num = num
      npid.save
    end
  end

  def self.down
    remove_index  :national_patient_identifiers, :decimal_num
    remove_column :national_patient_identifiers, :decimal_num
  end
end
