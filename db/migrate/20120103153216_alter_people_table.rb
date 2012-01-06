class AlterPeopleTable < ActiveRecord::Migration
  def self.up
    change_table :people do |p|
      p.string :national_id, :null => true
      p.string :given_name, :null => true
      p.string :family_name, :null => true
      p.string :gender, :null => true
      p.date :birthdate, :null => true
      p.boolean :birthdate_estimated, :null => false
    end
  end

  def self.down
     remove_column :people, :identifier
     remove_column :people, :given_name
     remove_column :people, :family_name
     remove_column :people, :gender
     remove_column :people, :birthdate
     remove_column :people, :birthdate_estimated
  end
end
