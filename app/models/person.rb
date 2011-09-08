class Person < ActiveRecord::Base

  def to_json
    self.data
  end

  def self.find_remote(id)
    return nil if SITE_CONFIG[:mode] == 'master'

  end

  def to_param
    self.national_id
  end

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options])['people']
  end

  # return a new, unsaved Person object fetched from the central repository.
  # If no record can be found or we hit a connection problem, the block is
  # yielded and can be used to do error handling.
  def self.find_remote(national_id, &block)
    base_resource.instance_variable_set '@block', block
    base_resource[national_id].get(:accept => :json) do |response, request, result, &block|
      case result
      when :ok
        logger.error "successssfully fetched #{national_id} from remote: #{response}"
        return Person.new :national_id => national_id, :data => response
      else
        logger.error "failed fetching #{national_id} from remote: #{result}"
        yield response, request, result if block_given?
      end
    end
    nil
  rescue Errno::ECONNREFUSED
    yield nil, nil, :connection_refused if block_given?
    nil
  end

end
