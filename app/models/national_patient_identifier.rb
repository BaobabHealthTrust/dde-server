class NationalPatientIdentifier < ActiveRecord::Base
  belongs_to :person
  belongs_to :assigner,
      :class_name => 'User'
  belongs_to :assigner_site,
      :class_name => 'Site'

  validates_presence_of :value, :assigner_site_id

  # don't allow more than one ID to be assigned to any person
  validates_uniqueness_of :person_id,
      :allow_nil => true

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

  def self.base_resource
    RestClient::Resource.new(SITE_CONFIG[:master_uri], SITE_CONFIG[:remote_http_options].to_hash.symbolize_keys)['national_patient_identifiers']['site'][Site.current_id]
  end

  def self.next_id_val(site_code, last_number = nil)
    npid_version  = '1'
    npid_prefix   = "P#{npid_version}#{site_code.rjust(3, '0')}"
    last_number ||= self.first(:conditions => ['left(value, 5) = ?', npid_prefix], :order => 'value DESC').try(:value) || '0'

    next_number = (last_number[5..-2].to_i + 1).to_s.rjust(7, '0')
    national_id_without_check_digit = "#{npid_prefix}#{next_number}"
    "#{national_id_without_check_digit}#{self.check_digit(national_id_without_check_digit[1..-1])}"
  end

  def self.check_digit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect(&:to_i)
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit, index|
      digit = digit * 2 if index % 2 == parity
      digit = digit - 9 if digit > 9
      sum  += digit
    end

    checkdigit = 0
    checkdigit += 1 while ((sum + checkdigit) % 10) != 0
    return checkdigit
  end

end
