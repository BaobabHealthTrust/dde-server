class Person < ActiveRecord::Base

  before_create :set_version_number
  after_update :set_version_number
  after_update :update_remote,
      :if => lambda { SITE_CONFIG[:mode] == 'master' }

  def to_json
    self.data
  end

  def to_param
    self.national_id
  end

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options])['people']
  end

  def base_resource
    @base_resource ||= self.class.base_resource[self.national_id]
  end

  # return a new, unsaved Person object fetched from the central repository.
  # If no record can be found or we hit a connection problem, the block is
  # yielded and can be used to do error handling.
  def self.find_remote(national_id, &block)
    return nil if SITE_CONFIG[:mode] == 'master'
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

  # updates a record on the remote site after it has been updated locally
  # (triggered locally)
  def update_remote(&block)
    with_remote_site do |remote|
      remote.put(self.remote_payload, :accept => :json) do |response, request, result, &block|
        case result
        when :ok
          logger.error "successssfully updated #{national_id} on remote: #{response}"
          return true
        when :conflict
          logger.error "conflict while trying to update #{national_id} on remote: #{response}"
          return false
        else
          logger.error "failed to update #{national_id} from remote: #{result}"
          yield response, request, result if block_given?
        end
      end
      nil
    end
  end

  def save_remote(&block)
    with_remote_site do |remote|
    end    
  end

  def create_remote(&block)
    with_remote_site do |remote|
    end
  end

  def with_remote_site(&block)
    return nil if SITE_CONFIG[:mode] == 'master'
    base_resource.instance_variable_set '@block', block
    yield base_resource
#   rescue Errno::ECONNREFUSED
#     yield nil, nil, :connection_refused if block_given?
#     nil
  end

  def update_attributes_with_version_number_verification(attributes)
    version = attributes.delete(:version_number)
    if self.version_number == version
      return self.update_attributes_without_version_number_verification(attributes)
    else
      self.errors.add :status, :conflict
      self.errors.add :status_message, "The version number you provided was #{version}, while the record here has #{self.version_number}. Please make sure you have the most recent record version before updating."

      return false
    end
  end
  alias_method_chain :update_attributes, :version_number_verification

  protected

  def remote_payload
    { :person    => self.attributes.merge(:creator_site_id => SITE_CONFIG[:site_id]) }
  end

  def set_version_number
    self.version_number = Guid.new
    self.save unless self.new_record?
  end

end
