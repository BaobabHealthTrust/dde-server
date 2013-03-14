# == Schema Information
#
# Table name: identifiers_to_be_assigned
#
#  id         :integer          not null, primary key
#  file       :string(255)
#  assigned   :string(255)
#  pulled_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#

class IdentifiersToBeAssigned < ActiveRecord::Base
  self.table_name = 'identifiers_to_be_assigned' 
end
