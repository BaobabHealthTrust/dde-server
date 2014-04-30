class NpidAutoGeneration < ActiveRecord::Base
  belongs_to :site
  
  validates :threshold, :site_id, :presence => true
  validates :threshold, :numericality => { :only_integer => true ,:greater_than => 0 }


  def self.generate_npids(params)
    @npid_request = NpidRequest.new params[:npid_request]
    saved = @npid_request.save
    return saved
  end
  
end
