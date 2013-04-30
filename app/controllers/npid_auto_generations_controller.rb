class NpidAutoGenerationsController < ApplicationController

  def create
    if Site.proxy?
      npid_autogenerate = NpidAutoGeneration.new
      npid_autogenerate.site_id = Site.current_id
      npid_autogenerate.threshold = params[:npid_auto_generation][:threshold]
      npid_autogenerate.save!
    end
    render :index
  end

  def edit
  end

  def index
    @npid_autogenerates = NpidAutoGeneration.all
  end

  def new
    @npid_autogenerate = NpidAutoGeneration.new
  end

  def show
  end

end
