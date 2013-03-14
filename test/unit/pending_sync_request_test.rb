# == Schema Information
#
# Table name: pending_sync_requests
#
#  id               :integer          not null, primary key
#  record_id        :integer
#  record_type      :string(255)
#  url              :string(255)
#  http_method      :string(255)
#  status_code      :string(255)
#  method_name      :string(255)
#  method_arguments :string(255)
#  request_body     :text
#  created_at       :datetime
#  updated_at       :datetime
#

require 'test_helper'

class PendingSyncRequestTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
