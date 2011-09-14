class PendingSyncRequest < ActiveRecord::Base
  belongs_to :record,
      :polymorphic => true

  def self.get(resource, record = nil, attributes = {})
    if record.is_a? Class
      self.new attributes.merge(:resource => resource, :record_type => record, :request_body => '', :method => 'get')
    else
      self.new attributes.merge(:resource => resource, :record => record, :request_body => '', :method => 'get')
    end
  end

  def self.put(resource, record, body, status, attributes = {})
    base_options = attributes.merge(:resource => resource, :request_body => body, :status_code => status, :method => 'put')
    if record.is_a? Class
      self.new base_options.merge(:record_type => record)
    else
      self.new base_options.merge(:record => record)
    end
  end

  def self.retry_delayed_requests!
    options = SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys
    self.where(:http_method => 'get').each do |pending_request|
      if pending_request.record_type and pending_request.method_name
        begin
          result = pending_request.record_type.constantize.send(pending_request.method_name, *pending_request.method_arguments)

#           puts "call to #{pending_request.record_type}.#{pending_request.method_name}(#{pending_request.method_arguments}) resulted in #{result.inspect}"

        rescue
          # nothing
        else
          pending_request.destroy
        end
      end
    end
  end

  def method_arguments
    ActiveSupport::JSON.decode(self[:method_arguments])
  end

#   def method_arguments=(*attrs)
#     self[:method_arguments] = attrs.to_json
#   end

end
