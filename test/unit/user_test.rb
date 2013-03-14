# == Schema Information
#
# Table name: users
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  password_hash :string(255)
#  email         :string(255)
#  description   :string(255)
#  disabled      :boolean          default(FALSE)
#  created_at    :datetime
#  updated_at    :datetime
#  site_id       :integer
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
