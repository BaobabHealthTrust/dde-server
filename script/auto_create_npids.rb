begin
	require 'rubygems'
	require 'rest-client'
	require 'json'
	require 'rails'
	LogErr = Logger.new("/var/www/dde-server/log/auto_npid.txt")
rescue => e
  LogErr.error(e.inspect)
end
AppPort = 3002
class AutoNpidService

  def self.auto_create_npids
   begin
  	results = RestClient.get("http://admin:admin@localhost:#{AppPort}/npid_auto_generations/create_npids")
   rescue => e
     LogErr.error(e.inspect)
   end
 end

  LogErr.info("Started at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  auto_create_npids
  LogErr.info("Finished at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  
end
