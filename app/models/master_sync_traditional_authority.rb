class MasterSyncTraditionalAuthority < ActiveRecord::Base

  def self.last_updated_datetime(district , traditional_authority)             
    self.where("district = ? AND traditional_authority = ?
      AND start_datetime IS NOT NULL AND end_datetime IS NOT NULL 
      AND transaction_completed = 1",district,traditional_authority).maximum(:end_datetime)
  end                                                                           
                                                                                
  def self.check_for_valid_start_date(district, traditional_authority)                                      
    if not(self.where("start_datetime IS NOT NULL AND end_datetime IS NULL 
      AND district = ? AND traditional_authority = ? AND transaction_completed = 0",
      district,traditional_authority).first).blank?       
        return true
    elsif(self.where("start_datetime IS NOT NULL AND end_datetime IS NULL 
        AND district = ? AND traditional_authority = ?",district,traditional_authority).last)
        return true
    elsif(self.where("start_datetime IS NOT NULL AND end_datetime IS NOT NULL 
        AND district = ? AND traditional_authority = ? AND transaction_completed = 0",
        district,traditional_authority).last)
        return true
    else
      self.create(:start_datetime => self.get_startdate(district, traditional_authority), 
        :district => district,:traditional_authority => traditional_authority)                                
    end                                                                         
  end

  def self.people_to_push(district,traditional_authority, site_code, last_updated_datetime = nil)
    return if district.blank? or traditional_authority.blank?

    search_district = 'address2":"' + district
    search_traditional_authority = '"county_district":"' + traditional_authority

    assigner_site_id = Site.where(:code => site_code)[0].try(:id)

    return if assigner_site_id.blank?

    if not last_updated_datetime.blank?                                       
      last_updated_datetime = last_updated_datetime.to_time.strftime('%Y-%m-%d %H:%M:%S')
      people = Person.joins(:national_patient_identifier).where("data LIKE (?) 
      AND data LIKE (?) AND people.updated_at > ? AND assigner_site_id <> ?",
      "%#{search_district}%","%#{search_traditional_authority}%",
      last_updated_datetime,assigner_site_id).select('people.*,
      national_patient_identifiers.value').order(:id).limit(20)
                                                                              
      self.check_for_valid_start_date(district,traditional_authority) unless people.blank?
      return people                     
    else                                                                      
      people = Person.joins(:national_patient_identifier).where("data LIKE (?) 
      AND data LIKE (?) AND assigner_site_id <> ?","%#{search_district}%",
      "%#{search_traditional_authority}%",assigner_site_id).select('people.*,
      national_patient_identifiers.value').order(:id).limit(20)
                                                                              
      self.check_for_valid_start_date(district,traditional_authority) unless people.blank?
      return people                      
    end 
  end 

  def self.update_transaction_end_datetime(district,traditional_authority,max_created_datetime)
   return if district.blank? or traditional_authority.blank?

   self.where("district = ? AND traditional_authority = ? AND transaction_completed = 0
     AND end_datetime IS NULL",district,
     traditional_authority).update_all(:end_datetime => max_created_datetime.to_time)
  end

  def self.acknowledge_push(district,traditional_authority)
   return false if district.blank? or traditional_authority.blank?

   self.where("district = ? AND traditional_authority = ? AND transaction_completed = 0
     AND end_datetime IS NOT NULL",district,
     traditional_authority).update_all(:transaction_completed => true) == 1
  end

  private

  def self.get_startdate(district, traditional_authority)
    date = self.where("district = ? AND traditional_authority = ?
      AND start_datetime IS NOT NULL AND end_datetime IS NOT NULL 
      AND transaction_completed = 1",district,traditional_authority).maximum(:end_datetime)
    
    unless date.blank?  
      return Person.where("updated_at > ?", date).minimum(:created_at) || Time.now()
    end
    Person.minimum(:created_at) || Time.now()
  end

end
