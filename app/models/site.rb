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

  def self.master?
    SITE_CONFIG[:mode] == 'master'
  end

  def self.proxy?
    SITE_CONFIG[:mode] == 'proxy'
  end

end
