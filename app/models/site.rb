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
    self.find self.current_id
  end

  def self.current_name
    self.current.try(:name) || '- unknown -'
  end

  def self.master?
    SITE_CONFIG[:mode] == 'master'
  end

  def self.proxy?
    SITE_CONFIG[:mode] == 'proxy'
  end

  def self.sync_with_master
    # TODO: proper error handling
    response = self.base_resource.get(:accept => :json)
    ActiveSupport::JSON.decode(response).each do |data_set|
      site = Site.find_or_initialize_by_id data_set['site'].delete('id')
      site.update_attributes data_set['site']
    end
  end

  protected

  def self.base_resource
    @base_resource ||= RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['sites']
  end

end
