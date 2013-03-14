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

class NationalIdSite < ActiveRecord::Base
end
