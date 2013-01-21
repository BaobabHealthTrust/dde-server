class MasterSync < ActiveRecord::Base
  def self.last_updated_date(site_code)             
    self.where("created_at IS NOT NULL AND ")
  end                                                                           
                                                                                
  def self.check_for_valid_start_date                                           
    if(self.where("start_date IS NOT NULL AND end_date IS NULL")).blank?        
      self.create(:start_date => DateTime.now())                                
    end                                                                         
  end
end
