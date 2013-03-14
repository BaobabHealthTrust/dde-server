# == Schema Information
#
# Table name: national_id_sites
#
#  id          :integer          not null, primary key
#  national_id :string(255)      not null
#  site_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'test_helper'

class NationalIdSiteTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
