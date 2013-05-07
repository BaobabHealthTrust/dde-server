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
        npid_request["last_timestamp"] = Time.now
        npid_request["site_code"] = set_site.site.code
        npid_request["count"] =  set_site.threshold
        params[:npid_request] = npid_request
        NpidAutoGeneration.generate_npids(params)
    end
  end

  def get_npids_in_batch(count)
    if Site.proxy?
      params = {}
      npid_request = {}
      npid_request["last_timestamp"] = Time.now
      npid_request["site_code"] = Site.current.code
      npid_request["count"] = count
      params[:npid_request] = npid_request
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/npid_requests/get_npids/"
      json_text = RestClient.post(uri,params)
      ids = JSON.parse(json_text)

      unless ids.blank?
        filename = ids['file_name']
        `touch #{Rails.root}/npids/#{filename}`
        l = Logger.new(Rails.root.join("npids",filename))

        (ids['ids']).each do |id|
          l.info "#{id}"
        end

        batch_info = {}

        file_info = `cksum #{Rails.root}/npids/#{filename}`.split(' ')
        batch_info[:check_sum] = file_info[0]
        batch_info[:file_size] = file_info[1]
        batch_info[:file_name] = filename
        complete_transfer = (filename == batch_info[:file_name])

        if complete_transfer
          IdentifiersToBeAssigned.create!(:file => filename,:assigned => 0, :pulled_at => Time.now())
        end

        return filename if complete_transfer
        return complete_transfer unless complete_transfer
      end
    end
  end

  def acknowledge(file_name)
    params = {}
    params[:file] = file_name
    if Site.proxy?
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/npid_requests/acknowledge/"
      resp = RestClient.post(uri,params)
      return resp
    else
      resp = false
      ids = []
      File.open("#{Rails.root}/npids/#{params[:file]}", "r").each_line do |line|
        ids << line.sub("\n",'')
      end

      resp = NationalPatientIdentifier.where('value IN(?) AND pulled IS NULL',ids).update_all(:pulled => true) != 0
      render :text => resp and return
    end
  end

  def save_requested_ids(file_name)
    resp = false
    file_found = IdentifiersToBeAssigned.where(:file => file_name, :assigned => 0).blank? != true

    if Site.proxy?
      ActiveRecord::Base.transaction do
        File.open("#{Rails.root}/npids/#{file_name}", "r").each_line do |line|
          id = line.sub("\n",'')
          success = NationalPatientIdentifier.create!(:value => id,:assigner_site_id => Site.current.id) rescue nil
          if success.blank?
            logger = Logger.new(Rails.root.join("log","requested_duplicate_ids.log"))
            logger.info id.to_s
          end
        end
        resp = IdentifiersToBeAssigned.where(:file => file_name,:assigned => 0).update_all(:assigned => 1) != 0
      end
    end if file_found
    return resp
  end

  def master_available_npids
    if Site.master?
      site = Site.find_by_code(params[:site_code])
      render :text => site.available_npids.count.to_json and return
    else
      params = {}
      params['site_code'] = Site.current.code
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/npid_auto_generations/master_available_npids/"
      available_npid_count = RestClient.post(uri,params)
      return JSON.parse(available_npid_count,:quirks_mode => true)
    end
  end

  def request_npids
    set_site = NpidAutoGeneration.find_by_site_id(Site.current_id)
    set_threshold = set_site.threshold
    available_npids = set_site.site.available_npids.count
    return false if available_npids > set_threshold

    available_ids_to_request = master_available_npids
    if available_ids_to_request > 0
      file_name = get_npids_in_batch(available_ids_to_request)
      if acknowledge(file_name).to_s == "true"
       return save_requested_ids(file_name)
      end
    end
  end

  def create_npids
    if Site.master?
      generate_npids
    else
      request_npids
    end
    render :text => "done" and return
  end

end
