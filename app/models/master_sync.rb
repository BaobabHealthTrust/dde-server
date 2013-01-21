class MasterSync < ActiveRecord::Base
  def self.last_updated_date(site_code)             

    all_sites = self.where("t1.created_at = ? AND t1.id = ?",)

                                    
    dates = MasterSync.where("site_code <> ? AND master_syncs.id = d.master_sync_id",
      site_code).joins('INNER JOIN master_sync_details d')
  end                                                                           
                                                                                
  def self.check_for_valid_start_date                                           
    if(self.where("start_date IS NOT NULL AND end_date IS NULL")).blank?        
      self.create(:start_date => DateTime.now())                                
    end                                                                         
  end
end
