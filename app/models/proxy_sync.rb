class ProxySync < ActiveRecord::Base

  def self.last_updated_date
    date = self.where("start_date IS NOT NULL AND end_date IS NULL")
    return date.first.start_date unless date.blank?
    self.where("start_date IS NOT NULL 
      AND end_date IS NOT NULL").maximum(:end_date).try(:end_date)
  end

  def self.check_for_valid_start_date
    if(self.where("start_date IS NOT NULL AND end_date IS NULL")).blank?
      self.create(:start_date => DateTime.now())
    end
  end

end
