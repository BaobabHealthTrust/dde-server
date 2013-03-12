class MasterSyncs < ActiveRecord::Base

  def self.last_updated_datetime(site_code)             
    datetime = self.where("site_code = ? AND created_date IS NOT NULL 
      AND updated_date IS NOT NULL",site_code).maximum(:created_at)
    unless datetime.blank?                                                      
      #something went wrong - so what this block will do is: give query for a date when
      #the sync was complete.                                                   
      sync_complete_date = self.where("created_date IS NOT NULL                   
      AND updated_date IS NOT NULL AND site_code = ?",site_code).maximum(:created_at)                           
    end                                                                         
                                                                                
    unless sync_complete_date.blank?                                            
      return sync_complete_date                                                 
    else                                                                        
      return self.where("created_date IS NOT NULL 
        AND updated_date IS NOT NULL AND site_code = ?",site_code).maximum(:created_at)
    end
  end                                                                           
                                                                                
  def self.check_for_valid_start_date(site_code)                                      
    if not(self.where("created_date IS NOT NULL AND updated_date IS NULL AND site_code = ?",site_code).first).blank?       
      return true
    elsif(self.where("created_date IS NOT NULL AND updated_date IS NOT NULL AND site_code = ?",site_code).last)
      self.create(:created_date => Date.today, :site_code => site_code)                                
    else
      self.create(:created_date => Date.today, :site_code => site_code)                                
    end                                                                         
  end
end
