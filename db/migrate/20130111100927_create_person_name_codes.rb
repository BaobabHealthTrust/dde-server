class CreatePersonNameCodes < ActiveRecord::Migration
  def self.up
    create_table :person_name_codes do |t|
      t.integer :person_id, :null => false
      t.string :given_name_code, :null => false
      t.string :family_name_code, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :person_name_codes
  end
end
