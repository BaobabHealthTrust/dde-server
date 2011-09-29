class NpidRequest

  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::AttributeMethods

  define_attribute_methods ['count', 'site_code']

  attr_accessor :attributes

  validates_numericality_of :count,
      :only_integer => true

  validates_length_of :site_code,
      :is => 3

  def initialize(attributes = {})
    @attributes = attributes
  end

  def save
    if Site.master
      generate!
    else
      request!
    end
  end

  def generate!
    raise 'Patient IDs can only be generated in master mode!' unless Site.master?

    if self.count > 0
      last_number = nil
      (0..count).map do
        id = NationalPatientIdentifier.create! self.attributes.merge(:value => NationalPatientIdentifier.next_id_val(self.site_code, last_number))
        last_number = id.value
        id
      end
    end
  end

  def request!
    raise 'Patient IDs can only be requested in proxy mode!' unless Site.proxy?

    payload = {:npid => self.attributes, :last_timestamp => self.order(:created_at).last.try(:created_at)}
    base_resource['generate'].post(payload, :accept => :json) do |response, request, result, &block|
      case result
      when Net::HTTPCreated
        logger.info "successssfully fetched new NPIDs from remote: #{response}"
        return ActiveSupport::JSON.decode(response).map do |attributes|
          self.create! attributes['national_patient_identifier']
        end
      else
        logger.error "failed fetching new NPIDs from remote: #{result}"
        yield response, request, result if block_given?
        []
      end
    end
  rescue Errno::ECONNREFUSED => e
    self.errors.add_to_base 'Could not establish a connection to the master service. Try again later.'
  end
end
