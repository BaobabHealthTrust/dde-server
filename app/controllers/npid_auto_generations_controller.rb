class NpidAutoGenerationsController < ApplicationController

  def create
    if Site.proxy?
      npid_threshold_setting = NpidAutoGeneration.new
      npid_threshold_setting.site_id = Site.current_id
      npid_threshold_setting.threshold = params[:npid_auto_generation][:threshold]
      npid_threshold_setting.save!
    else
      npid_threshold_setting = NpidAutoGeneration.new
      npid_threshold_setting.site_id = params[:npid_auto_generation][:site_id]
      npid_threshold_setting.threshold = params[:npid_auto_generation][:threshold]
      npid_threshold_setting.save!
    end

   redirect_to npid_auto_generations_path
   
  end

  def index
    @npid_settings = NpidAutoGeneration.page(params[:page]).all

    if Site.master?
      npid_set_sites = NpidAutoGeneration.count
      sites = Site.count
      @unset_sites_count = sites - npid_set_sites
    else
      @site_not_set = NpidAutoGeneration.count == 0 ? true : false
    end

  end

  def new
    @npid_setting = NpidAutoGeneration.new

    if Site.master?
      @npid_set_sites = NpidAutoGeneration.all.collect(&:site_id)
      unless @npid_set_sites.blank?
        @sites = Site.where("id NOT IN (?)", @npid_set_sites)
      else
        @sites = Site.all
      end
    end
    
  end

  def edit
    @npid_setting = NpidAutoGeneration.find(params[:id])
 
    if Site.master?
      @npid_set_sites = NpidAutoGeneration.all.collect(&:site_id)
      unless @npid_set_sites.blank?
        @sites = Site.where("id NOT IN (?)", @npid_set_sites)
      else
        @sites = Site.all
      end
    end

  end

  def update
    npid_setting = NpidAutoGeneration.find(params[:id])
    npid_setting.threshold = params[:npid_auto_generation][:threshold]
    npid_setting.save!
    redirect_to npid_auto_generations_path
  end

  def destroy
    NpidAutoGeneration.find(params[:id]).destroy
    redirect_to npid_auto_generations_path
  end

end
