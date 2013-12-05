class SitesController < ApplicationController
  
  # GET /sites
  # GET /sites.xml
  def index
    @sites = Site.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @sites }
      format.xml  { render :xml  => @sites }
    end
  end

  # GET /sites/1
  # GET /sites/1.xml
  def show
    @site = Site.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @site }
      format.xml  { render :xml  => @site }
    end
  end

  # GET /sites/new
  # GET /sites/new.xml
  def new
    @site = Site.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @site }
      format.xml  { render :xml  => @site }
    end
  end

  # GET /sites/1/edit
  def edit
    @site = Site.find(params[:id])
  end

  # POST /sites
  # POST /sites.xml
  def create
    @site = Site.new(params[:site])

    respond_to do |format|
      if @site.save
        format.html { redirect_to(@site, :notice => 'Site was successfully created.') }
        format.json { render :json => @site, :status => :created, :location => @site }
        format.xml  { render :xml  => @site, :status => :created, :location => @site }
      else
        format.html { render :action => "new" }
        format.json { render :json => @site.errors, :status => :unprocessable_entity }
        format.xml  { render :xml  => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sites/1
  # PUT /sites/1.xml
  def update
    @site = Site.find(params[:id])

    respond_to do |format|
      if @site.update_attributes(params[:site])
        format.html { redirect_to(@site, :notice => 'Site was successfully updated.') }
        format.json { head :ok }
        format.xml  { head :ok }
      else
        format.html { render :action => '#edit' }
        format.json { render :json => @site.errors, :status => :unprocessable_entity }
        format.xml  { render :xml  => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.xml
  def destroy
    @site = Site.find(params[:id])
    @site.destroy

    respond_to do |format|
      format.html { redirect_to(sites_url) }
      format.json { head :ok }
      format.xml  { head :ok }
    end
  end

  def index_remote
    resp = Site.sync_with_master!
    @sites  = Site.all

    if resp == "OK" 
      flash[:notice] = 'Sync with master completed successfully!'
    else 
      flash[:error] = resp
    end

    respond_to do |format|
      format.html { render :action => 'index' }
      format.json { render :json => @sites }
      format.xml  { render :xml => @sites }
    end
  end

  def perform_basic_auth
    if %w(index show index_remote).include? params[:action]
      super
    else
      authorize! :manage, Site
    end
  end

  def last_sync(site_code)
    if Site.master?
      site_name = Site.find_by_code(site_code).name rescue nil
      return "Unknown Site" if site_name.blank?
      complete_sync = nil
      last_incomplete_sync = MasterSyncs.where("site_code = '#{site_code}'
                                    AND created_date IS NOT NULL
                                    AND updated_date IS NULL").
                              order("created_date DESC").
                              select("created_date").
                              limit(1)

      unless last_incomplete_sync.blank?
           complete_sync = false
           return site_name,complete_sync,last_incomplete_sync.first.created_date
      else
           last_sync = MasterSyncs.where("site_code = '#{site_code}'
                                          AND created_date IS NOT NULL
                                          AND updated_date IS NOT NULL").
                                          order("updated_date DESC").
                                          select("updated_date").
                                          limit(1)
           unless last_sync.blank?
             complete_sync = true
             return site_name,complete_sync,last_sync.first.updated_date
           else
             return site_name,complete_sync
           end
      end  
    end
  end

end
