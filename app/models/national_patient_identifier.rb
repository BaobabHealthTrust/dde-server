class NationalPatientIdentifier < ActiveRecord::Base
  belongs_to :person
  belongs_to :assigner,
      :class_name => 'User'
  belongs_to :assigner_site,
      :class_name => 'Site'

  validates_presence_of :value, :assigner_site_id

  validates_uniqueness_of :person_id # don't allow more than one ID to be assigned to any person

  def self.generate!(options)
    raise 'Patient IDs can only be generated in master mode!' unless Site.master?

    count = options.delete(:count).to_i
    if count > 0
      0.upto count do |i|
        self.create! options.merge(:value => Guid.new.to_s)
      end
    end
  end

  def self.request!(options)
    raise 'Patient IDs can only be requested in proxy mode!' unless Site.proxy?
    payload = {:npid => options, :last_timestamp => self.order(:created_at).last.try(:created_at)}
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
      end
    end
  end

  def self.base_resource
    RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['national_patient_identifiers']
  end

  def self.find_or_create_from_attributes(attrs)
    if attrs['value']
      self.find_or_initialize_by_value(attrs['value']).tap do |new_record|
        new_record.update_attributes(attrs)
      end
    else
      raise ArgumentError, %q(expected attrs hash to have key named 'value')
    end
  end

end
