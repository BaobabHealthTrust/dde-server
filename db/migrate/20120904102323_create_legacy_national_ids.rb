class LegacyNationalIds < ActiveRecord::Migration
  def self.up
    create_table :legacy_national_ids do |t|                           
      t.string   :value                                                         
      t.string   :person_id                                                     
                                                                                
      t.timestamps                                                              
    end
  end

  def self.down
    drop_table :legacy_national_ids
  end
end
