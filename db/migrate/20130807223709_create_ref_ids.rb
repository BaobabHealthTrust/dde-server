class CreateRefIds < ActiveRecord::Migration
  def self.up
    create_table :ref_ids do |t|
      t.string :value
      
      t.timestamps
    end
    
    min = SITE_CONFIG[:base_npid].to_i
    max = min + SITE_CONFIG[:npid_range].to_i
  
    generated_ids = NationalPatientIdentifier.select('decimal_num').map(&:decimal_num)
    possible_ids ||= (min..max).map{|i| i}
    available_ids = possible_ids - generated_ids
    
    # save the reference ids in a random order
    available_ids.shuffle.each do |num|
      RefId.create!(:value => num)
    end
  end

  def self.down
    drop_table :ref_ids
  end
end
