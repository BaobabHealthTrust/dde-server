class MasterSync < ActiveRecord::Base
  def self.last_updated_date(site_code)             
    self.where("site_code <> ? created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).minmum(:updated_date).try(:updated_date)
  end                                                                           
                                                                                
  def self.check_for_valid_start_date(site_code)                                      
    if(self.where("created_date IS NOT NULL AND updated_date IS NULL AND site_code = ?",site_code)).blank?        
      self.create(:created_date => DateTime.now())                                
    end                                                                         
  end
end
