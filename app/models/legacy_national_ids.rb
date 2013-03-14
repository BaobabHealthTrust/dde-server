# == Schema Information
#
# Table name: legacy_national_ids
#
#  id          :integer          not null, primary key
#  value       :string(255)
#  person_id   :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  voided      :integer          default(0)
#  void_reason :string(255)
#  voided_date :datetime
#

class LegacyNationalIds < ActiveRecord::Base
  default_scope where(:voided => false)
  belongs_to :person

end
