class NpidAutoGeneration < ActiveRecord::Base
  belongs_to :site
  
  validates :threshold, :site_id, :presence => :true
  validates :threshold, :numericality => { :only_integer => true }
  validates :threshold, :numericality => { :greater_than => 0 }

end
