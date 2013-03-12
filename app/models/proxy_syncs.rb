class ProxySyncs < ActiveRecord::Base

  def self.last_updated_datetime
    datetime = self.where("start_date IS NOT NULL AND end_date IS NULL")
    unless datetime.blank?
      #something went wrong - so what this block will do is: give query for a date when
      #the sync was complete.
      sync_complete_date = self.where("start_date IS NOT NULL 
      AND end_date IS NOT NULL").maximum(:created_at)
    end

    unless sync_complete_date.blank?
      return sync_complete_date
    else
      return self.where("start_date IS NOT NULL AND end_date IS NOT NULL").maximum(:created_at)
    end
  end

  def self.check_for_valid_start_date
    if not(self.where("start_date IS NOT NULL AND end_date IS NULL").blank?)
      return true
    elsif (self.where("start_date IS NOT NULL AND end_date IS NOT NULL").last).blank?
      self.create(:start_date => Date.today)
    else
      self.create(:start_date => Date.today)
    end
  end

end
