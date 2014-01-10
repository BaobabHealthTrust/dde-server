require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'

LogErr = Logger.new('/var/www/dde-server/log/sync.txt')
ProxyPort = 3001

class SyncService

  def self.get_available_ids
    @url = "http://admin:admin@localhost:#{ProxyPort}/people/proxy_people_to_sync"
    results = RestClient::Request.execute(:method => :get, :url => @url, :timeout => 90000000)
    current_ids = JSON.parse(results)

    patients_ids_batch = self.compile_ids(current_ids)

    self.send_demographics_file(patients_ids_batch) unless patients_ids_batch.blank?
    self.get_demographics_from_master
    puts "Sync completed ...."
  end

  def self.get_demographics_from_master
    @url = "http://admin:admin@localhost:#{ProxyPort}/people/master_people_to_sync"
    results = RestClient::Request.execute(:method => :get, :url => @url, :timeout => 90000000)
    current_ids = JSON.parse(results) rescue JSON.parse(results.gsub('"',''))

    (self.compile_ids(current_ids) || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      @url = "http://admin:admin@localhost:#{ProxyPort}/people/sync_demographics_with_proxy?#{param}"
      RestClient::Request.execute(:method => :get, :url => @url, :timeout => 90000000)
      puts "Got from master successfully .... #{ids.join(',')}"
      LogErr.info("Got from master successfully .... #{ids.join(',')}")
    end
    
    unless current_ids.blank?
      @url = "http://admin:admin@localhost:#{ProxyPort}/people/record_successful_sync?update_master=true"
      RestClient::Request.execute(:method => :get, :url => @url, :timeout => 90000000)
    end
  end

  def self.send_demographics_file(file)

    (file || {}).each do |key,ids|
      param = "patient_ids=#{ids.join(',')}"
      uri = "http://admin:admin@localhost:#{ProxyPort}/people/sync_demographics_with_master?#{param}"
      puts "url #{uri}"
      RestClient::Request.execute(:method => :get, :url => uri, :timeout => 90000000)
      puts "Send to master successfully .... #{ids.join(',')}"
      LogErr.info("Send to master successfully .... #{ids.join(',')}")
    end

    @url = "http://admin:admin@localhost:#{ProxyPort}/people/record_successful_sync"
    RestClient::Request.execute(:method => :get, :url => @url, :timeout => 90000000)
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
  LogErr.info("Started at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  get_available_ids
  LogErr.info("Finished at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  
end

