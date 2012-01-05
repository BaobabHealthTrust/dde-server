class AlterPeopleTable < ActiveRecord::Migration
  def self.up
    change_table :people do |p|
      #p.string :national_id, :null => true
      p.string :given_name, :null => true
      p.string :family_name, :null => true
      p.string :gender, :null => true
    end
  end

  def self.down
     #remove_column :people, :identifier
     remove_column :people, :given_name
     remove_column :people, :family_name
     remove_column :people, :gender
  end
end
