class AddPulledToNationalPatientIdentifiers < ActiveRecord::Migration
  def self.up
    change_table :national_patient_identifiers do |n|
      n.boolean :pulled, :null => true, :after => :person_id
    end
  end

  def self.down
    remove_column :national_patient_identifiers, :pulled
  end
end
