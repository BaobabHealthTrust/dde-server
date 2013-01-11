class Sync < ActiveRecord::Base

  def self.last_updated_date(site_code)
    self.where(:'sync_site_id' => site_code).maximum(:updated_date)
  end

  def self.last_updated_person_id(site_code)
    self.where(:'sync_site_id' => site_code).maximum(:last_person_id)
  end

end
