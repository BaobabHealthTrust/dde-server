require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'

MasterPort = 3002

class SyncOuputService

  def self.last_sync
    site_codes = get_site_codes
    site_codes.each do |code|
       sync_output = RestClient.get("http://admin:admin@localhost:#{MasterPort}/sites/last_sync?site_code=#{code}")
       output = JSON.parse(sync_output)
       output_string = "Site : #{output[0]}"
       output_string += " ### Complete Sync? : #{output[1]}" unless output[1].nil?
       output_string += " ### Never Synced Before" if output[1].nil?
       output_string += " ### Date : #{output[2]}" unless output[1].nil?
       puts output_string
    end
  end

  def self.get_site_codes
    site_codes_output = RestClient.post("http://admin:admin@localhost:#{MasterPort}/sites/site_codes",nil)
    site_codes = JSON.parse(site_codes_output)
    return site_codes
  end

  last_sync

end

