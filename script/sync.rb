class SyncService

  def self.get_available_ids
    results = RestClient.get('http://admin:admin@localhost:3001/people/people_to_sync')
    raise results.to_s
    current_ids = JSON.parse(results)

    patients_ids_batch = self.compile_ids(current_ids)

    self.send_demographics_file(patients_ids_batch) unless patients_ids_batch.blank?
    self.get_demographics_from_master
    puts "Sync completed ...."
  end

  def self.get_demographics_from_master
    results = RestClient.get("http://admin:admin@localhost:3001/people/getPeopleIdsCount")
    current_ids = JSON.parse(results) 

    (self.compile_ids(current_ids) || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      RestClient.get("http://admin:admin@localhost:3001/people/sync_demographics_with_proxy?#{param}")
    end
  end

  def self.send_demographics_file(file)
    (file || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      RestClient.get("http://admin:admin@localhost:3001/people/sync_demographics_with_master?#{param}")
    end
  end

  def self.compile_ids(current_ids)
    return {} if current_ids.blank?
    patients_ids_batch = {}
    count = 1                                              
    patients_ids_batch[count] = []
    ids = []

    (current_ids || []).each do |person_id|
      if (patients_ids_batch[count].length < 11) 
        ids << person_id                                             
        patients_ids_batch[count] = ids                                         
      else                                         
        count+=1                                          
        ids = []                                                               
        ids << person_id                                              
        patients_ids_batch[count] = ids
      end
    end
    patients_ids_batch
  end
  
  get_available_ids
end

