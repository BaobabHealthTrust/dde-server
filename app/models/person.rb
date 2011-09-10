class Person < ActiveRecord::Base
  # dummy accessors
  attr_accessor :status, :status_message
  
  has_one :national_patient_identifier
  
  before_create :set_version_number, :set_npid
  after_save :save_npid
  after_update :set_version_number
  after_update :update_remote,
      :if => lambda { Site.proxy? }

  validates_presence_of :national_patient_identifier, :data
  
  def data
    ActiveSupport::JSON.decode(read_attribute :data)
  end

  def data=(new_data)
    if new_data.is_a? String
      write_attribute :data, new_data
    else
      write_attribute :data, new_data.to_json
    end
  end

  def to_param
    self.npid.try(:value) || self.id.to_s
  end

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['people']
  end

  def base_resource
    @base_resource ||= self.class.base_resource[self.npid]
  end

  # return a new, unsaved Person object fetched from the central repository.
  # If no record can be found or we hit a connection problem, the block is
  # yielded and can be used to do error handling.
  def self.find_remote(npid, &block)
    return nil if Site.master?
    base_resource.instance_variable_set '@block', block
    base_resource[npid].get(:accept => :json) do |response, request, result, &block|
      case result
      when Net::HTTPOK
        logger.info "successssfully fetched #{npid} from remote: #{response}"
        return self.new_from_json response
      else
        logger.error "failed fetching #{npid} from remote: #{result}"
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
        when Net::HTTPOK
          logger.error "successssfully updated #{npid} on remote: #{response}"
          return true
        when Net::HTTPConflict
          logger.error "conflict while trying to update #{npid} on remote: #{response}"
          return false
        else
          logger.error "failed to update #{npid} from remote: #{result}"
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
    return nil if Site.master?
    base_resource.instance_variable_set '@block', block
    yield base_resource
#   rescue Errno::ECONNREFUSED
#     yield nil, nil, :connection_refused if block_given?
#     nil
  end

  def update_attributes_with_version_number_verification(attributes)
    version = attributes.delete(:version_number)
    if self.version_number.to_s == version.to_s
      return self.update_attributes_without_version_number_verification(attributes)
    else
      self.errors.add :status, :conflict
      self.errors.add :status_message, "The version number you provided was #{version}, while the record here has #{self.version_number}. Please make sure you have the most recent record version before updating."

      return false
    end
  end
  alias_method_chain :update_attributes, :version_number_verification

  def npid
    self.national_patient_identifier
  end

  def npid=(obj)
    self.national_patient_identifier = obj
  end

  def npid_value
    self.npid.try(:value) || @npid_value
  end

  def npid_value=(new_value)
    self.set_npid NationalPatientIdentifier.find_by_value(new_value)
    @npid_value = new_value
  end

  def self.new_from_json(json_string)
    options = ActiveSupport::JSON.decode(json_string)['person']
    self.new options
  end

  protected

  def remote_payload
    { :person => self.attributes.merge(:creator_site_id => Site.current_id) }
  end

  def set_version_number
    self.version_number = Guid.new.to_s
#     self.save unless self.new_record?
  end

  def set_npid(npid = nil)
    npid ||= NationalPatientIdentifier.where(:assigned_at => nil).first
    if npid
      self.national_patient_identifier = npid
    else
      raise 'You have run out of national patient ids, please request a new block to be asigned to you!'
    end
  end

  def save_npid
    unless self.npid.assigned_at
      self.npid.update_attributes \
          :assigned_at      => Time.now,
          :assigner_id      => self.creator_id,
          :assigner_site_id => self.creator_site_id
    end
  end

end
