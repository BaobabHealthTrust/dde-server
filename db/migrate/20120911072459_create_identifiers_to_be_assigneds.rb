class CreateIdentifiersToBeAssigneds < ActiveRecord::Migration
  def self.up
    create_table :identifiers_to_be_assigned do |t|
      t.string   :file                                                          
      t.string   :assigned                                                      
      t.datetime :pulled_at 
  
      t.timestamps
    end
  end

  def self.down
    drop_table :identifiers_to_be_assigned
  end
end
