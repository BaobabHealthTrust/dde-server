class NpidRequest
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :npids, :errors

  def count=(val)
    self.attributes['count'] = val
  end

  def count
    self.attributes['count']
  end

  def site_code=(val)
    self.attributes['site_code'] = val
  end

  def site_code
    self.attributes['site_code']
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  validates_numericality_of :count,
      :only_integer => true

  validates_length_of :site_code,
      :is => 3

  def self.create(attrs = {}, &block)
    self.new(attrs).save &block
  end

  def initialize(attributes = {})
    self.attributes = attributes if attributes
  end

  def attributes=(attrs)
    self.attributes.merge! attrs
  end

  def attributes
    @attributes ||= {'count' => nil, 'site_code' => nil}
  end

  def persisted?
    false
  end

  def site
    @site ||= Site.find_by_code self.site_code
  end

  def save(&block)
    if valid?
      if Site.master?
        self.npids = generate!
      else
        self.npids = request! &block
      end
      self.npids and self.npids.any?
    end
  end

  def generate!
    raise 'Patient IDs can only be generated in master mode!' unless Site.master?

    if self.count and self.count > 0
      last_number = nil
      site = Site.where(:code => self.site_code).first
      ids = NationalPatientIdentifier.where('assigner_site_id = ? AND (pulled IS NULL OR pulled != 1)', site.id).limit(self.count)
      
      ids = (1 .. self.count).map do
        id = NationalPatientIdentifier.create!(
               :value => NationalPatientIdentifier.next_id_val(SITE_CONFIG[:npid_version],
                                                               self.site_code, last_number),
               :assigner_site => self.site)
        last_number = id.value
        id
      end if ids.blank?
      
      ids
    end
  end

  def request!
    raise 'Patient IDs can only be requested in proxy mode!' unless Site.proxy?
    self.site_code = Site.current_code

    payload = {:npid_request => self.attributes.merge(:last_timestamp => NationalPatientIdentifier.order(:created_at).last.try(:created_at))}
    self.class.base_resource.post(payload, :accept => :json) do |response, request, result, &block|
      case result
      when Net::HTTPCreated
        Rails.logger.info "successssfully fetched new NPIDs from remote: #{response}"
        return ActiveSupport::JSON.decode(response).map do |attributes|
          NationalPatientIdentifier.create! attributes['national_patient_identifier']
        end
      else
        err = "failed fetching new NPIDs from remote: #{result}"
        self.errors.add :base, err
        Rails.logger.error err
        yield response, request, result if block_given?
        []
      end
    end
  rescue Errno::ECONNREFUSED => e
    self.errors.add :base, 'Could not establish a connection to the master service. Try again later.'
  end

  def self.base_resource
    RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['npid_requests']
  end

  def valid?
    sanitize_input
    super
  end

  def sanitize_input
    self.count = self.count.to_i
  end
end
