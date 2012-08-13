# v3 Id: P + Version + Site Code + Sequential Number + Check Digit
# v4 Id: base30(Random Number + Check Digit)
#
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

  # create the decimal equivalent of the Id value if it has not yet been set
  before_save do |npid|
    if npid.decimal_num.blank?
      num = NationalPatientId.to_decimal(npid.value, 30) / 10
      npid.decimal_num = num
    end
  end
  
  self.per_page = 20

  min = SITE_CONFIG[:base_npid].to_i
  max = min + SITE_CONFIG[:npid_range].to_i
  @@possible_ids ||= (min..max).map
  
  @@generated_ids ||= NationalPatientIdentifier.where('decimal_num IS NOT NULL').map(&:decimal_num)
  @@last_id ||= NationalPatientIdentifier.last.id rescue nil

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
      NationalPatientId.new(NationalPatientIdentifier.next_random_num).value
    else
      raise ArgumentError, %Q(Unsupported version "#{version}". Should be 3 or 4)
    end
  end
  
  def self.next_random_num
    if @@last_id
      @@generated_ids += NationalPatientIdentifier.select('id').where(['id > ?', @@last_id]).map(&:id)
    else
      @@generated_ids = NationalPatientIdentifier.select('id').map(&:id)
    end
    @@last_id = NationalPatientIdentifier.select('id').last.id rescue nil
    available_ids = @@possible_ids - @@generated_ids
    
    available_ids[rand(available_ids.length)]
  end

end
