class Sync < ActiveRecord::Base

  def self.last_updated_date(site_code)
    self.where(:'sync_site_id' => site_code).order("MAX(updated_date) DESC").first.try(:updated_date)
  end

end
