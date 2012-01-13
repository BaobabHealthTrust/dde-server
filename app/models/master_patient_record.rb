	class MasterPatientRecord < ActiveRecord::Base
    self.establish_connection :healthdata
	  set_table_name "MasterPatientRecord"
    set_primary_keys :Site_ID, :Pat_ID
    
    def self.create_healthdata_patient(received_params)
      params = received_params["person"]["data"]
      birthdate = params["birthdate"].to_date                                                      
    patient_hash = {                                                            
        "First_Name" => params["names"]["given_name"],                          
        "Last_Name" => params["names"]["family_name"],                          
        "Sex" => params["gender"],                                              
        "Day_Of_Birth" => birthdate.day,                                        
        "Month_Of_Birth" => birthdate.month,                                    
        "Year_Of_Birth" => birthdate.year,                                      
       # "Birth_TA" => params["addresses"]["address2"],                          
        "Location" => 0,                                                        
       # "Address" => "#{addresses['state_province']} / #{addresses['county_district']} / #{addresses['city_village']}",
        "Site_ID" => 101,                                                       
        "Pat_ID" => MasterPatientRecord.maximum(:Pat_ID).to_i + 1,              
        "Birth_Date" => birthdate.strftime("%d-%b-%Y"),                 
        "Date_Reg" => Date.today.strftime("%d-%b-%Y")                           
        }                                                                       
                                                                                
    #raise patient_hash.to_yaml                                                 
    patient = MasterPatientRecord.create(patient_hash)                          
  end                                        
  
  
    
  end  
