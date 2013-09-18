# == Schema Information
#
# Table name: people
#
#  id                    :integer          not null, primary key
#  data                  :text
#  created_at            :datetime
#  updated_at            :datetime
#  version_number        :string(255)      default("0")
#  creator_id            :string(255)
#  creator_site_id       :string(255)
#  remote_version_number :string(255)
#  given_name            :string(255)
#  family_name           :string(255)
#  gender                :string(255)
#  birthdate             :date
#  birthdate_estimated   :boolean          not null
#

class Person < ActiveRecord::Base
  # dummy accessors
  attr_accessor :status, :status_message

  has_one :national_patient_identifier
  has_many :legacy_national_ids,:class_name => 'LegacyNationalIds', 
           :foreign_key => 'person_id'
  has_many :person_name_codes,:class_name => 'PersonNameCode',
           :foreign_key => 'person_id'

  belongs_to :creator,
      :class_name => 'User'
  belongs_to :creator_site,
      :class_name => 'Site'

  before_validation do |person| 
    set_npid
    person.creator_id = User.current_user.id
  end
  
  #before_save :set_remote_version_number
  self.after_save :save_npid

  validates_presence_of :national_patient_identifier, :data

  self.per_page = 20

  def data
    ActiveSupport::JSON.decode(read_attribute :data)
  rescue
    {}
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
    logger.info "fetching from remote: #{npid}"
    base_resource.instance_variable_set '@block', block
    base_resource[npid].get(:accept => :json) do |response, request, result, &block|
      case result
      when Net::HTTPOK
        logger.info "successssfully fetched #{npid} from remote: #{response}"
        return self.find_or_initialize_from_attributes ActiveSupport::JSON.decode(response)
      else
        logger.error "failed fetching #{npid} from remote: #{result}"
        yield response, request, result if block_given?
      end
    end
    nil
  rescue Errno::ECONNREFUSED
    yield nil, base_resource[npid], :connection_refused if block_given?
    nil
  end

  # updates a record on the remote site after it has been updated locally
  # (triggered locally)
  def update_remote(&block)
    ensure_no_recursive_update_calls do
      with_remote_site do |remote|
        remote.put(self.remote_attributes, :accept => :json) do |response, request, result|
          decoded_response = ActiveSupport::JSON.decode(response) rescue nil
          case result
          when Net::HTTPOK
            logger.error "successssfully updated #{self.npid_value} on remote: #{response}"
            # After a successful update we get a new version number from the server.
            # This we have to store locally, otherwise future update requests would fail.
            new_version_number = decoded_response['person']['version_number']
            if new_version_number
              self.remote_version_number = new_version_number
              self.version_number        = new_version_number
            else
              raise 'The response from the server did not contain a new version number!'
            end
            return true
          else
            logger.error "Failed to update #{self.npid_value} to remote: #{result.message}"
            yield response, request, result if block_given?
            return false
          end
        end
        nil
      end
    end
  rescue Errno::ECONNREFUSED
    yield nil, base_resource, :connection_refused if block_given?
    nil
  end

  def with_remote_site
    return nil if Site.master?
    yield base_resource
  end

  # Updates the record if the version number provided was correct.
  # If there was a conflict (i.e. version number mismatch) the block is yielded
  def update_attributes_with_version_number_verification(options)
    attributes = options.dup
    version    = attributes.delete(:version_number)
    if self.version_number_was.to_s == version.to_s
      self.set_version_number
      return self.update_attributes_without_version_number_verification(attributes)
    else
      self.attributes = attributes
      logger.error "Conflict while trying to update #{self.npid_value} locally."
      yield if block_given?
      return false
    end
  end
  alias_method_chain :update_attributes, :version_number_verification

#   # Returns true if the _local_ version was successfully saved for remote
#   # error handling that may or may not occur during remote update, please
#   # use a block that will be passed the response, request and result objects
#   # from the HTTP library
#   def update_attributes_with_pushing_to_master(attributes, &block)
#     attributes['remote_version_number'] ||= version_number_was
#     self.update_attributes_without_pushing_to_master(attributes).tap do |local_success|
#       if local_success and Site.proxy?
#         self.version_number = attributes['remote_version_number']
#         self.update_remote &block
#       end
#     end
#   end
#   alias_method_chain :update_attributes, :pushing_to_master

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
        'version_number'  => self.remote_version_number,
        'remote_version_number' => self.remote_version_number,
        'created_at'      => self.created_at,
        'updated_at'      => self.updated_at,
        'creator_id'      => self.creator_id,
        'creator_site_id' => Site.current_id
      }
    }.merge(self.npid.try(:remote_attributes) || {}).merge(self.creator_site.try(:remote_attributes) || {})
  end

  def data_as_yaml
    self.data.to_yaml
  end

  def data_as_yaml=(new_str)
    self.data = YAML.load(new_str)
  end

  def self.pull_from_master(npid_or_person)
    if npid_or_person.is_a? Person
      npid = npid_or_person.npid_value
    else
      npid = npid_or_person
    end

    person = self.find_remote(npid) do |response, request, result|
      PendingSyncRequest.get(
        :record_type      => 'Person',
        :method_name      => 'pull_from_master',
        :method_arguments => [npid].to_json,
        :status_code      => (result.respond_to?(:message) ? result.message : result),
        :url              => request.url)
    end
    person.save if person
  end

  def push_to_remote
    self.version_number = self.remote_version_number
    self.update_remote do |response, request, result|
      PendingSyncRequest.put(
        :record           => self,
        :method_name      => 'push_to_remote',
        :method_arguments => [npid].to_json,
        :status_code      => (result.respond_to?(:message) ? result.message : result),
        :url              => request.url)
    end
  end
  
  def assign_npid
    self.set_npid
  end

  def self.search(params)
    gender = params[:gender]
    given_name_code = params[:given_name].squish.soundex unless params[:given_name].blank?
    family_name_code = params[:family_name].squish.soundex unless params[:family_name].blank?

    Person.joins(:person_name_codes).where("given_name_code LIKE '%#{given_name_code}%' 
      AND family_name_code LIKE '%#{family_name_code}%' AND gender = ?", 
      gender).limit(20).map do |person|
        JSON.parse(person.to_json)
    end
  end

  protected

  def set_version_number
    self.version_number = Guid.new.to_s
  end
=begin
  def set_remote_version_number
    self.remote_version_number ||= Guid.new.to_s
  end
=end
  def set_npid(npid = nil)
    if self.npid_value.blank? and npid.nil?
      npid ||= NationalPatientIdentifier.order('id ASC').where(:assigned_at => nil).first
      if npid
        self.national_patient_identifier = npid
      else
        raise 'You have run out of national patient ids, please request a new block to be assigned to you!'
      end
    end
  end

  def save_npid
    if self.npid.assigned_at.blank?
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

  def ensure_key_present(hash, key)
    unless hash[key]
      raise ArgumentError, "Argument Hash is expected to contain the '#{key}' key. Present keys include: #{hash.keys.join(', ')}"
    end
  end

  def self.after_save
    PersonNameCode.create_name_code(self)
  end

end
