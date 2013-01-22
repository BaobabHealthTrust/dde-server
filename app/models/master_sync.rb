class MasterSync < ActiveRecord::Base
  def self.last_updated_date(site_code)             
    date = self.where("site_code <> ? AND created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).minimum(:updated_date)
    return date unless date.blank?  
      
    self.where("site_code = ? AND created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).maximum(:created_date)
  end                                                                           
                                                                                
  def self.check_for_valid_start_date(site_code)                                      
    if(self.where("created_date IS NOT NULL AND updated_date IS NULL AND site_code = ?",site_code)).blank?        
      self.create(:created_date => DateTime.now(),:site_code => site_code)                                
    end                                                                         
  end
end
