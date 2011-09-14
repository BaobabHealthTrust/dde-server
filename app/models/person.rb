class Person < ActiveRecord::Base
  # dummy accessors
  attr_accessor :status, :status_message, :remote_version_number

  has_one :national_patient_identifier

  belongs_to :creator,
      :class_name => 'User'
  belongs_to :creator_site,
      :class_name => 'Site'

  before_create :set_version_number, :set_npid
  after_save :save_npid
  before_update :set_version_number,
      :if => lambda { Site.master? }

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

  def to_json(options={})
    includes = (options[:includes] || []).inject({}){|mem, assoc| mem[assoc.to_s] = self.send assoc }
    self.remote_attributes.merge(includes).to_json
  end

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['people']
  end

  def base_resource
    @base_resource ||= self.class.base_resource[self.npid_value]
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
        return self.find_or_initialize_from_attributes ActiveSupport::JSON.decode(response)
      else
        PendingSyncRequest.find_or_create_by_record_type_and_method_name_and_method_arguments(
          :record_type      => 'Person',
          :method_name      => 'find_remote',
          :http_method      => 'get',
          :method_arguments => [npid].to_json,
          :status_code      => result.message,
          :url              => request.url)
        logger.error "failed fetching #{npid} from remote: #{result}"
        yield response, request, result if block_given?
      end
    end
    nil
  rescue Errno::ECONNREFUSED
    PendingSyncRequest.find_or_create_by_record_type_and_method_name_and_method_arguments(
      :record_type      => 'Person',
      :method_name      => 'find_remote',
      :http_method      => 'get',
      :method_arguments => [npid].to_json,
      :status_code      => 'Connection Refused',
      :url              => base_resource[npid].url)
    yield nil, base_resource[npid], :connection_refused if block_given?
    nil
  end

  # updates a record on the remote site after it has been updated locally
  # (triggered locally)
  def update_remote(&block)
    ensure_no_recursive_update_calls do
      with_remote_site do |remote|
        remote.put(self.remote_attributes, :accept => :json) do |response, request, result, &block|
          decoded_response = ActiveSupport::JSON.decode(response) rescue nil
          case result
          when Net::HTTPOK
            logger.error "successssfully updated #{self.npid_value} on remote: #{response}"
            # After a successful update we get a new version number from the server.
            # This we have to store locally, otherwise future update requests would fail.
            new_version_number = decoded_response['person']['version_number']
            if new_version_number
              self.update_attribute :version_number, new_version_number
            else
              raise 'The response from the server did not contain a new version number!'
            end
            return true
          else
            logger.error "failed to update #{self.npid_value} to remote: #{result}"
            yield response, request, result if block_given?
          end
        end
        nil
      end
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
    if self.version_number_was.to_s == version.to_s
      return self.update_attributes_without_version_number_verification(attributes)
    else
      logger.error "conflict while trying to update #{self.npid_value} locally."
      self.attributes = attributes
      yield self.dup.reload if block_given?
      return false
    end
  end
  alias_method_chain :update_attributes, :version_number_verification

  def update_attributes_with_pushing_to_master(attributes, &block)
    self.update_attributes_without_pushing_to_master(attributes, &block).tap do |result|
      if result and Site.proxy?
        self.version_number = attributes['remote_version_number'] unless attributes['remote_version_number'].blank?
        self.update_remote do |response, request, result|
          case result
          when Net::HTTPConflict
            logger.error "conflict while trying to update #{self.npid_value} on remote: #{response}"
            if block_given?
              decoded_response = ActiveSupport::JSON.decode(response)
              yield self.class.initialize_from_attributes(decoded_response)
            end
          else
            PendingSyncRequest.find_or_create_by_record_type_and_method_name_and_method_arguments(
              :record      => self,
              :http_method => 'put',
              :status_code => result.message,
              :url         => request.url)
          end
          return false
        end
      end
    end
  end
  alias_method_chain :update_attributes, :pushing_to_master

  def npid
    self.national_patient_identifier
  end

  def npid=(obj)
    self.national_patient_identifier = obj
  end

  def npid_value
    @npid_value || self.npid.try(:value)
  end

  def npid_value=(new_value)
    new_npid = NationalPatientIdentifier.find_by_value(new_value)
    if new_npid
      self.set_npid new_npid
      @npid_value = new_value
    else
      raise "NPID #{new_value} does not exist"
    end
  end

  def self.find_by_npid_value(npid_value)
    self.includes(:national_patient_identifier).where(:'national_patient_identifiers.value' => npid_value).first
  end

  def self.find_or_initialize_from_attributes(attrs, options = {})
    person = self.find_by_npid_value(attrs['npid']['value'])
    if person.nil?
      person ||= Person.initialize_from_attributes(attrs)
    else
      person.attributes = attrs['person']
      person.initialize_associations_from_attributes(attrs)
    end
  end

  def self.initialize_from_attributes(attrs, options = {})
    self.new(attrs['person']).initialize_associations_from_attributes(attrs)
  end

  def initialize_associations_from_attributes(attrs)
    ensure_key_present(attrs, 'site')
    ensure_key_present(attrs, 'npid')

    self.npid         = NationalPatientIdentifier.find_or_create_from_attributes(attrs['npid'], :update => true)
    self.creator_site = Site.find_or_create_from_attributes(attrs['site'], :update => true)
    self
  end

  def remote_attributes
    { 'person' => {
        'data'            => self.data,
        'version_number'  => self.version_number,
        'created_at'      => self.created_at,
        'updated_at'      => self.updated_at,
        'creator_id'      => self.creator_id,
        'creator_site_id' => Site.current_id
      }
    }.merge(self.npid.try(:remote_attributes) || {}).merge(self.creator_site.try(:remote_attributes) || {})
  end

  protected

  def set_version_number
    self.version_number = Guid.new.to_s
  end

  def set_npid(npid = nil)
    unless self.npid_value and npid.nil?
      npid ||= NationalPatientIdentifier.where(:assigned_at => nil).first
      if npid
        self.national_patient_identifier = npid
      else
        raise 'You have run out of national patient ids, please request a new block to be asigned to you!'
      end
    end
  end

  def save_npid
    if self.npid.changed?
      self.npid.update_attributes \
          :assigned_at      => Time.now,
          :assigner_id      => self.creator_id,
          :assigner_site_id => self.creator_site_id
    end
  end

  # this is necessary because some updates trigger other updates in callbacks
  def ensure_no_recursive_update_calls
    unless @update_in_progress
      @update_in_progress = true
      yield
      @update_in_progress = false
    end
  end

  class Conflict < StandardError; end
  def handle_conflict(response)
    raise Conflict
  end

  def ensure_key_present(hash, key)
    unless hash[key]
      raise ArgumentError, "Argument Hash is expected to contain the '#{key}' key. Present keys include: #{hash.keys.join(', ')}"
    end
  end

end
