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

require 'test_helper'

class IdentifiersToBeAssignedTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
