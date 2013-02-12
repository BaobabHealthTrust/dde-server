class LegacyNationalIds < ActiveRecord::Base
  default_scope where(:voided => false)
  belongs_to :person

end
