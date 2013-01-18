class Sync < ActiveRecord::Base

  def self.last_updated_date(site_code)
    if Site.proxy?
      self.where(:'sync_site_id' => site_code).maximum(:updated_date)
    else
      dates = []
      sites = Site.all
      sites.each do |site|
        next if site.code == site_code
        dates << self.where(:'sync_site_id' => site.code).maximum(:updated_date)
      end
      dates.sort.first
    end
  end

  def self.last_updated_person_id(site_code)
    self.where(:'sync_site_id' => site_code).maximum(:last_person_id)
  end

end
