require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'

LogErr = Logger.new(ENV['PWD'].sub('script','log/sync.txt'))

class SyncService

  def self.get_available_ids
    results = RestClient.get('http://admin:admin@localhost:3001/people/people_to_sync')
    current_ids = JSON.parse(results)

    patients_ids_batch = self.compile_ids(current_ids)

    self.send_demographics_file(patients_ids_batch) unless patients_ids_batch.blank?
    self.get_demographics_from_master
    puts "Sync completed ...."
  end

  def self.get_demographics_from_master
    results = RestClient.get("http://admin:admin@localhost:3001/people/getPeopleIdsCount")
    current_ids = JSON.parse(results) rescue JSON.parse(results.gsub('"',''))

    (self.compile_ids(current_ids) || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      RestClient.get("http://admin:admin@localhost:3001/people/sync_demographics_with_proxy?#{param}")
      puts "Got from master successfully .... #{ids.join(',')}"
      LogErr.info("Got from master successfully .... #{ids.join(',')}")
    end
  end

  def self.send_demographics_file(file)
    (file || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      RestClient.get("http://admin:admin@localhost:3001/people/sync_demographics_with_master?#{param}")
      puts "Send to master successfully .... #{ids.join(',')}"
      LogErr.info("Send to master successfully .... #{ids.join(',')}")
    end
  end

  def self.compile_ids(current_ids)
    return {} if current_ids.blank?
    patients_ids_batch = {}
    count = 1                                              
    patients_ids_batch[count] = []
    ids = []

    (current_ids.sort || []).each do |person_id|
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
    patients_ids_batch.sort{|a,b| a <=> b }
  end
  
  get_available_ids
  
end

