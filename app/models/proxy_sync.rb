class ProxySync < ActiveRecord::Base

  def self.last_updated_date
    date = self.where("start_date IS NOT NULL AND end_date IS NULL")
    return date.first.start_date unless date.blank?
    self.where("start_date IS NOT NULL 
      AND end_date IS NOT NULL").maximum(:end_date)
  end

  def self.check_for_valid_start_date
    if not(self.where("start_date IS NOT NULL AND end_date IS NULL")).blank?
      if(Person.count < 1)
        self.create(:start_date => DateTime.now())
      else
        self.create(:start_date => (Person.where('id > 0').minimum('created_at') - 1.minute))
      end
    elsif not(self.where("start_date IS NOT NULL AND end_date IS NOT NULL").last).blank?
      if(Person.count < 1)
        self.create(:start_date => DateTime.now())
      else
        self.create(:start_date => (Person.where('id > 0').maximum(:updated_at)))
      end
    end
  end

end
