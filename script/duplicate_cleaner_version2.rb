LogErr = Logger.new(Rails.root.join("log","duplicates_error.txt"))
LogSuc = Logger.new(Rails.root.join("log","success.txt"))

class DuplicateCleaner < ActiveRecord::Migration
  def self.duplicate_national_ids
    national_id_values = NationalPatientIdentifier.select("value, count(value) as idcount").
                                            group("value").having("idcount >= 2").
                                            order("value,decimal_num").collect{|npid|npid.value}
    return national_id_values
  end

  def self.delete_duplicates
   duplicates = duplicate_national_ids
   counter = 0
	 people_counter = 0
   duplicates.each do |duplicate|
     dups = NationalPatientIdentifier.find_all_by_value(duplicate)
     dups.each do |dup|
       dup.delete
       unless dup.person_id.blank?
				 people_counter = people_counter + 1
         Person.find(dup.person_id).delete
			   puts "Deleted person with id: #{dup.person_id} ##{people_counter}"
       end
       counter= counter + 1
			 puts "Deleted national_id:  #{dup.value} ##{counter}"
     end
   end
   return counter   
  end

  def self.assign_national_ids_decimal_num
    start = Time.now()
    puts "Started at #{start.strftime("%Y-%m-%d %H:%M:%S")}"
    national_ids = NationalPatientIdentifier.where("decimal_num IS NULL").order("value")
    LogSuc.info "There are  #{national_ids.count} ids that were assigned with decimal num"
    puts "There are  #{national_ids.count} ids that were assigned without decimal num"
    updated_national_ids = []
    national_ids.each do|national_id|
      if national_id.decimal_num.blank?
        national_id.decimal_num = NationalPatientId.to_decimal(national_id.value, 30) / 10
        national_id.save! rescue LogErr.info("failed to update >> #{national_id.value} for >> #{national_id.person_id}") and next
        puts "updated #{national_id.value} <<<<<<<<<<<<<<<<"
        LogSuc.info "updated #{national_id.value}"
        updated_national_ids << national_id.value
      end
    end

    puts "There were #{national_ids.count} assigned national ids without decimal num"
    puts "#{updated_national_ids.count} national ids were updated"
    puts "#{national_ids.count - updated_national_ids.count} national ids were not updated"
    puts "Started at :#{start.strftime("%Y-%m-%d %H:%M:%S")} ##### finished at :#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
  end
  
  def self.add_index_to_decimal_num  
    add_index :national_patient_identifiers, :decimal_num, :unique => true
  end
 start = Time.now()
 counter = delete_duplicates
 puts "Started  deletion at at #{start.strftime("%Y-%m-%d %H:%M:%S")}"
 puts "Finished detetion at at :#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
 puts "Deleted #{counter} national identifiers"
 assign_national_ids_decimal_num
 add_index_to_decimal_num 

end
