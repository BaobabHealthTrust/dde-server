class NpidAutoGenerationsController < ApplicationController

  def create
    if Site.proxy?
      @npid_threshold_setting = NpidAutoGeneration.new
      @npid_threshold_setting.site_id = Site.current_id
      @npid_threshold_setting.threshold = params[:npid_auto_generation][:threshold]
    else
      @npid_threshold_setting = NpidAutoGeneration.new
      @npid_threshold_setting.site_id = params[:npid_auto_generation][:site_id]
      @npid_threshold_setting.threshold = params[:npid_auto_generation][:threshold]
    end

    respond_to do |format|
      if @npid_threshold_setting.save
          format.html { redirect_to(npid_auto_generations_path, :notice => 'NPID threshold setting was successfully created.') }
          format.xml  { render :xml => @npid_threshold_setting, :status => :created, :location => @npid_threshold_setting }
      else
          format.html { render :action => 'new' }
          format.xml  { render :xml => @npid_threshold_setting.errors, :status => :unprocessable_entity }
      end
    end
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

    respond_to do |format|
        format.html
    end

  end

  def new
    @npid_threshold_setting = NpidAutoGeneration.new

    if Site.master?
      @npid_set_sites = NpidAutoGeneration.all.collect(&:site_id)
      unless @npid_set_sites.blank?
        @sites = Site.where("id NOT IN (?)", @npid_set_sites)
      else
        @sites = Site.all
      end
    end

    respond_to do |format|
        format.html
    end
    
  end

  def edit
    @npid_threshold_setting = NpidAutoGeneration.find(params[:id])
 
    if Site.master?
      @npid_set_sites = NpidAutoGeneration.all.collect(&:site_id)
      unless @npid_set_sites.blank?
        @sites = Site.where("id NOT IN (?)", @npid_set_sites)
      else
        @sites = Site.all
      end
    end

    respond_to do |format|
        format.html
    end

  end

  def update
    @npid_threshold_setting = NpidAutoGeneration.find(params[:id])
    @npid_threshold_setting.threshold = params[:npid_auto_generation][:threshold]
    
    respond_to do |format|
      if @npid_threshold_setting.save
          format.html { redirect_to(npid_auto_generations_path, :notice => 'NPID threshold setting was successfully updated.') }
          format.xml  { head :ok }
      else
          format.html { render :action => 'new' }
          format.xml  { render :xml => @npid_threshold_setting.errors, :status => :unprocessable_entity }
      end
    end
    
  end

  def destroy
    @npid_threshold_setting = NpidAutoGeneration.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to(npid_auto_generations_url, :notice => 'NPID threshold setting was successfully destroyed.') }
      format.xml  { head :ok }
    end

  end

  def generate_npids
    @set_sites = NpidAutoGeneration.all
    @set_sites.each do |set_site|
        next if set_site.site.available_npids.count > 0
        params = {}
        npid_request = {}
        npid_request.merge!("last_timestamp" => Time.now)
        npid_request.merge!("site_code" => set_site.site.code)
        npid_request.merge!("count" =>  set_site.threshold)
        params.merge!(:npid_request => npid_request)
        NpidAutoGeneration.generate_npids(params)
    end
  end
  
end
