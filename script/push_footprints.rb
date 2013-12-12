require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'

LogErr = Logger.new('/var/www/dde-server/log/push_footprints.log')
ProxyPort = 3001

class FootPrintService

  def self.get_footprints_to_push
    results = RestClient.get("http://admin:admin@localhost:#{ProxyPort}/people/footprints_to_push")
    current_ids = JSON.parse(results)
    footprint_ids_batch = self.compile_ids(current_ids)
    self.send_footprints_file(footprint_ids_batch) unless footprint_ids_batch.blank?
    puts "Footprint push  completed ..."
  end  

  def self.send_footprints_file(file)
    (file || {}).each do |key,ids|
      param = "footprint_ids=#{ids.join(',')}"
      uri = "http://admin:admin@localhost:#{ProxyPort}/people/push_footprints_to_master?#{param}"
      puts "url #{uri}"
      RestClient.get(uri)
      puts "Sent  footprints to master successfully .... #{ids.join(',')}"
      LogErr.info("Sent footprints to master successfully .... #{ids.join(',')}")
    end

    RestClient.get("http://admin:admin@localhost:#{ProxyPort}/people/record_successful_footprint_push")
  end

  def self.compile_ids(current_ids)
    return {} if current_ids.blank?
    footprint_ids_batch = {}
    count = 1                                              
    footprint_ids_batch[count] = []
    ids = []

    (current_ids.sort || []).each do |footprint_id|
      if (footprint_ids_batch[count].length < 100)
        ids << footprint_id                                             
        footprint_ids_batch[count] = ids                                         
      else                                         
        count+=1                                          
        ids = []                                                               
        ids << footprint_id                                              
        footprint_ids_batch[count] = ids
      end
    end
    footprint_ids_batch.sort{|a,b| a <=> b }
  end
  LogErr.info("Started at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  get_footprints_to_push
  LogErr.info("Finished at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  
end

