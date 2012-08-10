class NationalPatientIdentifier < ActiveRecord::Base
  belongs_to :person
  belongs_to :assigner,
      :class_name => 'User'
  belongs_to :assigner_site,
      :class_name => 'Site', :foreign_key => 'assigner_site_id'

  validates_presence_of :value, :assigner_site_id

  # don't allow more than one ID to be assigned to any person
  validates_uniqueness_of :person_id,
      :allow_nil => true

  self.per_page = 20

  def self.find_or_create_from_attributes(attrs, options = {:update => false})
    if attrs['value']
      self.find_or_initialize_by_value(attrs['value']).tap do |npid|
        npid.update_attributes(attrs) if npid.new_record? or options[:update]
      end
    else
      raise ArgumentError, %q(expected attrs hash to have key named 'value')
    end
  end

  def remote_attributes
    { 'npid' => {
        'value'            => self.value,
        'assigner_site_id' => self.assigned_at,
        'assigned_at'      => self.assigned_at
      }
    }
  end

  def to_json
    self.remote_attributes.to_json
  end

  protected

  def self.next_id_val(version, site_code=nil, last_number = nil)
    if version == 3
      raise ArgumentError, %q(site_code (2nd arg) is mandatory for version 3 ids) if site_code.blank?
      npid_version  = '1'
      npid_prefix   = "P#{npid_version}#{site_code.rjust(3, '0')}"
      last_number ||= self.first(:conditions => ['left(value, 5) = ?', npid_prefix], :order => 'value DESC').try(:value) || nil
      last_number ||= SITE_CONFIG[:base_npid] || '0'
      
      next_number = (last_number.to_s[5..-2].to_i + 1).to_s.rjust(7, '0')
      national_id_without_check_digit = "#{npid_prefix}#{next_number}"
      
      "#{national_id_without_check_digit}#{NationalPatientId.check_digit(national_id_without_check_digit[1..-1])}"
    elsif version == 4
      base_number ||= SITE_CONFIG[:base_npid].to_i
      new_number = base_number + rand(SITE_CONFIG[:npid_range])
      
      NationalPatientId.new(new_number).value
    else
      raise ArgumentError, %Q(Unsupported version "#{version}". Should be 3 or 4)
    end
  end

end
