require 'rubygems'
require 'rails'
require 'npid_requests_controller'

LogErr = Logger.new('/var/www/dde-auto-proxy/log/auto_npid.txt')

class AutoNpidService

  def self.auto_create_npids
   begin
  	npid_autogeneration = NpidAutoGenerationsController.new
    if Site.master?
     npid_autogeneration.generate_npids
    else
     npid_autogeneration.auto_request_npids
    end
   rescue => e
     LogErr.error(e.inspect)
   end
 end

  LogErr.info("Started at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  auto_create_npids
  LogErr.info("Finished at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  
end

