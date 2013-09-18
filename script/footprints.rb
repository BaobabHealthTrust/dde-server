require 'rubygems'                                                              
require 'rest-client'                                                           
require 'json'                                                                  
require 'rails'                                                                 
                                                                                
ProxyPort = 3001                                                                
                                                                                
class FootprintService
                                                                                
  def self.push_footprints_to_master                                                
    results = RestClient.get("http://admin:admin@localhost:#{ProxyPort}/people/push_footprints")
    puts "Footprints push: ....#{results}"                                                  
  end


  self.push_footprints_to_master
end
