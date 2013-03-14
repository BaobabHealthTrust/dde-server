# == Schema Information
#
# Table name: sites
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  annotations :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  code        :string(255)      default("")
#

require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
