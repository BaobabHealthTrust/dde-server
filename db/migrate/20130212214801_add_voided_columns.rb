class AddVoidedColumns < ActiveRecord::Migration
  def self.up
    add_column :national_patient_identifiers,:voided,:integer,:null => false,:default => 0,:after => :updated_at
    add_column :national_patient_identifiers,:void_reason,:string
    add_column :national_patient_identifiers,:voided_date,:datetime
    add_column :legacy_national_ids,:voided,:integer,:default => 0,:after => :updated_at
    add_column :legacy_national_ids,:void_reason,:string
    add_column :legacy_national_ids,:voided_date,:datetime
  end

  def self.down
  	remove_column :national_patient_identifiers,:voided
    remove_column :national_patient_identifiers,:void_reason
    remove_column :national_patient_identifiers,:voided_date
    remove_column :legacy_national_ids,:voided
    remove_column :legacy_national_ids,:void_reason
    remove_column :legacy_national_ids,:voided_date
  end
end
