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

require 'test_helper'

class LegacyNationalIdsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
