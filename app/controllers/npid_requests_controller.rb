class NpidRequestsController < ApplicationController

  def index
    redirect_to :action => :new
  end

  def new
    @npid_request = NpidRequest.new :count => 10
  end
  
  def create
    if Site.proxy?
      params[:npid_request].merge!('site_code' => Site.current_code)
    end

    @npid_request = NpidRequest.new params[:npid_request]

    respond_to do |format|
      if @npid_request.save
        @npids = @npid_request.npids
        format.html do
          if Site.proxy?
            flash[:notice] = "You have now #{@npids.size} new NPIDS assigned to your site."
            redirect_to national_patient_identifiers_path
          else
            flash[:notice] = "#{@npids.size} new NPIDS have been assigned to Site #{@npid_request.site_code}."
            redirect_to site_specific_national_patient_identifiers_path(@npid_request.site_code)
          end
        end
        format.json { render :json => @npids.to_json, :status => :created }
        format.xml  { render :xml  => @npids, :status => :created }
        format.txt  { render :text  => 'Assigned ID' }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @npid_request.errors, :status => :internal_server_error }
        format.xml  { render :xml  => @npid_request.errors, :status => :internal_server_error }
        format.txt  { render :text  => 'Assigned ID' }
      end
    end
  end

  def get_npids
    if Site.proxy?
      params[:npid_request].merge!('site_code' => Site.current.code)
      uri = "http://admin:admin@localhost:3002/npid_requests/get_npids/"
      npid = RestClient.post(uri,params)

      ack = false
      if npid
        NationalPatientIdentifier.create!(:value => npid,:assigner_site_id => Site.current.id)
        uri = "http://admin:admin@localhost:3002/npid_requests/ack/"
        ack = RestClient.post(uri,"ids[]=#{npid}")
      end
      resp = "#{ack}" 
    else
      @npid_request = NpidRequest.new params[:npid_request]
      saved = @npid_request.save
      ids = @npid_request.npids.map(&:value) 
      
      filename = (params[:npid_request]['site_code']) + Time.now().strftime('%Y%m%d%H%M%S') + '.txt'
      `touch #{Rails.root}/npids/#{filename}`
      l = Logger.new(Rails.root.join("npids",filename)) 

      (ids).each do |id|
        l.info "#{id}"
      end

      batch_info = {}

      file_info = `cksum #{Rails.root}/npids/#{filename}`.split(' ')
      batch_info[:check_sum] = file_info[0]
      batch_info[:file_size] = file_info[1]
      batch_info[:file_name] = filename
      batch_info[:ids] = ids
      resp = batch_info.to_json
    end
    
    render :text => resp
    return
  end
  
  def ack
    patient_ids = []
    patient_ids = params[:ids] if params[:ids]
    patient_ids.each do |id|
      npid = NationalPatientIdentifier.find_by_value(id)
      npid.pulled = true
      npid.save
    end
    
    respond_to do |format|
      format.txt { render :text => 'OK' }
    end
  end
  
  def get_npids_in_batch
    if Site.proxy?
      params[:npid_request].merge!('site_code' => Site.current.code)
      uri = "http://admin:admin@localhost:3002/npid_requests/get_npids/"
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
        complete_tranfer = (filename == batch_info[:file_name])

        if complete_tranfer
          IdentifiersToBeAssigned.create!(:file => filename,:assigned => 1, :pulled_at => Time.now())
        end

        render :text => filename if complete_tranfer
        render :text => complete_tranfer unless complete_tranfer
        return
      end
    end
    
  end

  def acknowledge
    if Site.proxy?
      uri = "http://admin:admin@localhost:3002/npid_requests/acknowledge/"
      resp = RestClient.post(uri,params) 
    else
      resp = false
      ids = []
      File.open("#{Rails.root}/npids/#{params[:file]}", "r").each_line do |line|
        ids << line.sub("\n",'')
      end
      
      resp = NationalPatientIdentifier.where('value IN(?) AND pulled IS NULL',ids).update_all(:pulled => true) != 0

    end
    render :text => resp and return
  end

  def save_requested_ids
    resp = false
    ActiveRecord::Base.transaction do
      File.open("#{Rails.root}/npids/#{params[:file]}", "r").each_line do |line|
        (ids['ids']).each do |id|
          NationalPatientIdentifier.create!(:value => id,:assigner_site_id => Site.current.id)
        end
      end
      resp = IdentifiersToBeAssigned.where(:file => filename,:assigned => 1).update_all(:assigned => 0) != 0
    end

    render :text => resp and return
  end


end
