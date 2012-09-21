class CreateNationalPatientIds < ActiveRecord::Migration
  def self.up
    remove_column :people, :national_id

    create_table :national_patient_identifiers do |t|
      t.string   :value
      t.string   :person_id
      t.datetime :assigned_at
      t.integer  :assigner_id
      t.integer  :assigner_site_id

      t.timestamps
    end
  end

  def self.down
    drop_table :national_patient_ids
    add_column :people, :national_id, :string
  end

end
