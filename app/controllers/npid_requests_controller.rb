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
      uri = "http://admin:admin@dde-master/npid_requests/get_npids/"
      npid = RestClient.post(uri,params)

      ack = false
      if npid
        NationalPatientIdentifier.create!(:value => npid,:assigner_site_id => Site.current.id)
        uri = "http://admin:admin@dde-master/npid_requests/ack/"
        ack = RestClient.post(uri,"ids[]=#{npid}")
      end
      render :text  => "#{ack}" 
      return
    end
    render :text  => "Err" 
    return
  end

end
