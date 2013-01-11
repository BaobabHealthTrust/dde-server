class CreatePersonNameCodes < ActiveRecord::Migration
  def self.up
    create_table :person_name_codes do |t|
      t.integer :person_id
      t.string :given_name_code
      t.string :family_name_code

      t.timestamps
    end
  end

  def self.down
    drop_table :person_name_codes
  end
end
