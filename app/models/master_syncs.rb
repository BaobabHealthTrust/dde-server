class MasterSyncs < ActiveRecord::Base

  def self.last_updated_datetime(site_code)             
    date = self.where("site_code <> ? AND created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).minimum(:created_at)
    return date unless date.blank?  
      
    self.where("site_code = ? AND created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).maximum(:created_at)
  end                                                                           
                                                                                
  def self.check_for_valid_start_date(site_code)                                      
    if(self.where("created_date IS NOT NULL AND updated_date IS NULL AND site_code = ?",site_code).first).blank?        
      self.create(:created_date => DateTime.now(),:site_code => site_code)                                
    elsif not(self.where("created_date IS NOT NULL AND updated_date IS NOT NULL AND site_code = ?",site_code).last).blank?        
      date = (self.where("created_date IS NOT NULL AND updated_date 
        IS NOT NULL AND site_code = ?",site_code)).maximum(:created_at)
      self.create(:created_date => date, :site_code => site_code)                                
    else
      self.create(:created_date => DateTime.now(),:site_code => site_code)                                
    end                                                                         
  end
end
