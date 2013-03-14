# == Schema Information
#
# Table name: people
#
#  id                    :integer          not null, primary key
#  data                  :text
#  created_at            :datetime
#  updated_at            :datetime
#  version_number        :string(255)      default("0")
#  creator_id            :string(255)
#  creator_site_id       :string(255)
#  remote_version_number :string(255)
#  given_name            :string(255)
#  family_name           :string(255)
#  gender                :string(255)
#  birthdate             :date
#  birthdate_estimated   :boolean          not null
#

require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
