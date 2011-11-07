class Site < ActiveRecord::Base

  has_many :users

  has_many :national_patient_identifiers,
      :foreign_key => :assigner_site_id

  def available_npids
    self.national_patient_identifiers.where(:assigned_at => nil)
  end

  def assigned_npids
    self.national_patient_identifiers.where('assigned_at IS NOT NULL')
  end

  def self.current_id
    SITE_CONFIG[:site_id].to_i
  end

  def self.current     
    if self.proxy?
      self.find self.current_id
    end
  end

  def self.current_name
    if self.proxy?
      self.current.try(:name) || '- unknown -'
    else
      'Master Service'
    end
  end

  def self.current_code
    if self.proxy?
      self.current.try(:code) || '???'
    else
      'DDE'
    end
  end

  def self.master?
    SITE_CONFIG[:mode] == 'master'
  end

  def self.proxy?
    SITE_CONFIG[:mode] == 'proxy'
  end

  def self.sync_with_master!
    if Site.proxy?
      response = self.base_resource.get(:accept => :json)
      ActiveSupport::JSON.decode(response).each do |data_set|
        self.find_or_create_from_attributes(data_set['site'], :update => true)
      end
    end
  rescue => e
    Rails.logger.error "#{e} while trying to fetch site information from master"
  end

  def self.find_or_create_from_attributes(attrs, options = {:update => false})
    if attrs['id']
      self.find_or_initialize_by_id(attrs.delete('id')).tap do |site|
        site.update_attributes(attrs) if site.new_record? or options[:update]
      end
    else
      raise ArgumentError, %q(expected attrs hash to have key named 'id')
    end
  end

  def remote_attributes
    { 'site' => self.attributes }
  end

  def to_json(includes = {})
    self.remote_attributes.merge(includes).to_json
  end

  protected

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['sites']
  end

end
