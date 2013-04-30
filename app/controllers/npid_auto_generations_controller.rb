class NpidAutoGenerationsController < ApplicationController

  def create
    if Site.proxy?
      npid_autogenerate = NpidAutoGeneration.new
      npid_autogenerate.site_id = Site.current_id
      npid_autogenerate.threshold = params[:npid_auto_generation][:threshold]
      npid_autogenerate.save!
    else
      npid_autogenerate = NpidAutoGeneration.new
      npid_autogenerate.site_id = params[:npid_auto_generation][:site_id]
      npid_autogenerate.threshold = params[:npid_auto_generation][:threshold]
      npid_autogenerate.save!
    end
   redirect_to npid_auto_generations_path
  end

  def index
    @npid_autogenerates = NpidAutoGeneration.all
  end

  def new
    @npid_autogenerate = NpidAutoGeneration.new
  end

  def destroy
    @npid_autogenerate = NpidAutoGeneration.find(params[:id]).destroy
    redirect_to npid_auto_generations_path
  end

end
