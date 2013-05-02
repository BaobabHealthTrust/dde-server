class NpidAutoGeneration < ActiveRecord::Base
  belongs_to :site
  
  validates :threshold, :site_id, :presence => true
  validates :threshold, :numericality => { :only_integer => true ,:greater_than => 0 }
  
end
