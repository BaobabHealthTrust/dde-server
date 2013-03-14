# == Schema Information
#
# Table name: person_name_codes
#
#  id               :integer          not null, primary key
#  person_id        :integer          not null
#  given_name_code  :string(255)      not null
#  family_name_code :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#

require 'test_helper'

class PersonNameCodeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
