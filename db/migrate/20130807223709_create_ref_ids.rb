class CreateRefIds < ActiveRecord::Migration
  def self.up
    create_table :ref_ids do |t|
      t.string :value
      t.string :trigesimal_value
      t.boolean :assigned, :default => false
   
      t.timestamps
    end
    
    min = SITE_CONFIG[:base_npid].to_i
    max = min + SITE_CONFIG[:npid_range].to_i
  
    generated_ids = NationalPatientIdentifier.select('decimal_num').map(&:decimal_num)
    possible_ids ||= (min..max).map{|i| i}
    available_ids = possible_ids - generated_ids
    rem_ids = available_ids.count
    # save the reference ids in a random order
    available_ids.shuffle.each do |num|
      trig_value  = NationalPatientId.new(num).value
      ref_id =  RefId.create!(:value => num, :trigesimal_value => trig_value)
     
    puts "Created id number >>> #{ref_id.id} ||| value >>> #{ref_id.value} ||| trigesimal_value >>> #{ref_id.trigesimal_value} ||| remaining  >>> #{rem_ids - ref_id.id}" 
    end
  end

  def self.down
    drop_table :ref_ids
  end
end
