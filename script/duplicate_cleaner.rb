LogErr = Logger.new(Rails.root.join("log","duplicates_error.txt"))
LogSuc = Logger.new(Rails.root.join("log","success.txt"))
class DuplicateCleaner
  def self.duplicate_national_ids
    national_id_values = NationalPatientIdentifier.select("value, count(value) as idcount").
                                            group("value").having("idcount >= 2").
                                            order("value,decimal_num").collect{|npid|npid.value}
    return national_id_values
  end

  def self.update_national_ids_decimal_num
    start = Time.now()
    ids = self.duplicate_national_ids
    national_ids = NationalPatientIdentifier.where("value in (?)",ids).order("value")

    national_ids.each do|national_id|
        if national_id.decimal_num and national_id.person_id.blank?
            national_id.delete rescue LogErr.info("failed to delete >> #{national_id.value} for >> #{national_id.person_id}") and next
            puts "deleted #{national_id.value} >>>>>>>>>>>>>>>>>"
        end
    end
   
    national_ids.each do|national_id|
      if national_id.decimal_num.blank? and national_id.person_id
        national_id.decimal_num = NationalPatientId.to_decimal(national_id.value, 30) / 10
        national_id.save! rescue LogErr.info("failed to update >> #{national_id.value} for >> #{national_id.person_id}") and next
        puts "updated #{national_id.value} <<<<<<<<<<<<<<<<"
      end
    end
    puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")} ########## finished at:#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
  end

  def self.assign_national_ids_decimal_num
    start = Time.now()
    puts "Started at #{start.strftime("%Y-%m-%d %H:%M:%S")}"
    national_ids = NationalPatientIdentifier.where("decimal_num IS NULL AND person_id IS NOT NULL").order("value")
    LogSuc.info "There are  #{national_ids.count} ids that were assigned with decimal num"
    puts "There are  #{national_ids.count} ids that were assigned without decimal num"
    updated_national_ids = []
    national_ids.each do|national_id|
      if national_id.decimal_num.blank? and national_id.person_id
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

 #update_national_ids_decimal_num
 assign_national_ids_decimal_num

end
