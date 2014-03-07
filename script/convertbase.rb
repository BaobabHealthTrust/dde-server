require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'
class ConvertBase
def converttobase30
ref_ids = RefId.where(:trigesimal_value => nil).limit(500000)
    ref_ids.each do |ref_id|
      begin
        ref_id.trigesimal_value  = NationalPatientId.new(ref_id.value).value
        ref_id.save!
      rescue Exception => e
        puts "Error : #{e}"
        next
      end
     puts "Saved >>> #{ref_id.id} || Decimal >>>  #{ref_id.value} || Base 30 >>>  #{ref_id.trigesimal_value}"
    end
end
converttobase30
end

