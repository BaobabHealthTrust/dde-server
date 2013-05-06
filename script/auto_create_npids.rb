require 'rubygems'
require 'rest-client'
require 'json'
require 'rails'

Modulepath = File.expand_path($PROGRAM_NAME)
AppPath = Modulepath.gsub($PROGRAM_NAME,"")
LogErr = Logger.new(File.join(AppPath,'log/auto_npid.txt'))

class AutoNpidService

  def self.auto_create_npids
  	npid_autogeneration = NpidAutoGenerationsController.new
    if Site.master?
     npid_autogeneration.generate_npids
    else
     npid_autogeneration.auto_request_npids
    end
  end

  LogErr.info("Started at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  auto_create_npids
  LogErr.info("Finished at : #{Time.now().strftime('%Y-%m-%d %H:%M:%S')}")
  
end

