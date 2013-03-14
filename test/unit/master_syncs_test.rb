# == Schema Information
#
# Table name: master_syncs
#
#  id           :integer          not null, primary key
#  site_code    :string(255)      not null
#  created_date :date
#  updated_date :date
#  created_at   :datetime
#  updated_at   :datetime
#

require 'test_helper'

class MasterSyncsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
