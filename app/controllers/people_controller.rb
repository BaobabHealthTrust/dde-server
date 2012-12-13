class PeopleController < ApplicationController

  before_filter :load_person,
      :only => [:show, :edit, :update, :destroy, :conflict]

  # GET /people
  # GET /people.xml
  def index
    @people = Person.page(params[:page]).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people }
    end
  end

  # GET /people/1
  # GET /people/1.xml
  # GET /people/1.json
  def show
    if @person.nil?
      if Site.master?
        head :not_found
      else
        show_remote
      end
    else
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml  => @person }
        format.json { render :json => @person.to_json }
      end
    end
  end

  # GET /people/find
  # GET /people/find.xml?given_name=:given_name&family_name=:family_name
  def find
    if not params[:value].blank?
      @people = Person.joins(:national_patient_identifier).where(params.slice(:given_name,
      :family_name, :family_name2,:city_village,                                  
      :gender).merge("national_patient_identifiers.value" => params[:value])).select("people.*,value")

      if @people.blank?
        national_id = params[:value].gsub('-','')
        @people = Person.joins([:national_patient_identifier,
          :legacy_national_ids]).where('legacy_national_ids.value' => national_id).select("people.*,national_patient_identifiers.value")

        (@people || []).each do |person|
          person.assign_npid if person.national_patient_identifier.blank?
        end 
      end

    else
      @people = Person.where(params.slice(:given_name,:family_name, :family_name2,
      :city_village, :gender)).joins(:national_patient_identifier).select("people.*,value")
    end

    case @people.size
    when 0
      if Site.master?
        head :not_found
      else
#       find_remote
        respond_to do |format|
          format.json do |f| 
            render :text => {}.to_json
          end
        end
      end
    when 1
      respond_to do |format|
        format.html do |f| 
          @person = @people.first
          render :action => 'show'
        end
        format.xml  { render :xml  => @people }
        format.json { render :json => @people.to_json }
      end
    else
      respond_to do |format|
        format.html { render :action => 'index',         :status => :multiple_choices }
        format.xml  { render :xml    => @people,         :status => :multiple_choices }
        format.json { render :json   => @people.to_json, :status => :multiple_choices }
      end
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
  end

  # POST /people
  # POST /people.xml
  def create
    # @healthdata_patient = MasterPatientRecord.create_healthdata_patient(params)
    # if @healthdata_patient
    #  params[:person]["data"]["patient"]["identifiers"]["old_identification_number"] = "#{@healthdata_patient.Site_ID.to_s}#{@healthdata_patient.Pat_ID.to_i.to_s}"
    # end

    passed_national_id = (params[:person]['data']['patient']['identifiers']['old_identification_number'])

    unless passed_national_id.blank?
      national_id = passed_national_id.gsub('-','').strip
      
      @person = Person.where("legacy_national_ids.value = ?",national_id).includes([:legacy_national_ids]).first rescue nil
      
      if @person.blank?
        @person = Person.where("national_patient_identifiers.value = ?",national_id).includes([:national_patient_identifier]).first rescue nil
      end

      if @person
        respond_to do |format|
            format.html { redirect_to(@person, :notice => 'Person was successfully created.') }
            format.xml  { render :xml  => @person, :status => :created, :location => @person }
            format.json { render :json => @person, :status => :created, :location => @person }
        end
      end
      return if not @person.blank?
    end

    @person = Person.new(params[:person].merge( 
                         {:creator_site_id => Site.current_id ,
                         :given_name => params[:person]["data"]["names"]["given_name"] ,
                         :family_name => params[:person]["data"]["names"]["family_name"] ,
                         :gender => params[:person]["data"]["gender"] ,
                         :birthdate => params[:person]["data"]["birthdate"] ,
                         :birthdate_estimated => params[:person]["data"]["birthdate_estimated"]}
                        ))

    respond_to do |format|
      if @person.save
        if not passed_national_id.blank?
          legacy_national_id = LegacyNationalIds.new()
          legacy_national_id.person_id = @person.id
          legacy_national_id.value = national_id
          legacy_national_id.save
        end
        format.html { redirect_to(@person, :notice => 'Person was successfully created.') }
        format.xml  { render :xml  => @person, :status => :created, :location => @person }
        format.json { render :json => @person, :status => :created, :location => @person }
      else
        status = @person.errors.delete(:status) || :unprocessable_entity

        format.html { render :action => 'new' }
        format.xml  { render :xml  => @person.errors, :status => status }
        format.json { render :json => @person.errors, :status => status }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    if @person.nil? # happens on master if records are 'created' by proxy
      @person = Person.find_or_initialize_from_attributes(params.slice(:person, :npid, :site))
      success = @person.save
    else
      success = @person.update_attributes(params[:person]) do # this block is only called on conflict
        flash[:error] = "Conflicting versions: new (#{params[:person][:version_number].last(12)}) vs. old (#{@person.version_number.last(12)}). NO changes have been saved!"
        handle_local_conflict(@person, @person.dup.reload) and return
      end

      if success and Site.proxy?
        @person.push_to_remote do |response, request, result| # this block is only called on error
          case result
          when Net::HTTPConflict
            logger.error "Conflict while updating #{params[:id]} on remote: #{response}"
            decoded_response = ActiveSupport::JSON.decode(response)
            remote_person    = Person.initialize_from_attributes(decoded_response)
            flash[:warning]  = "Conflicting versions: local (#{@person.version_number_was.last(12)}) vs. remote (#{remote_person.version_number.last(12)}). Your changes have been saved locally, so you may also resolve this conflict later."
            handle_remote_conflict(@person, remote_person) and return
          when :connection_refused
            msg = "No connection to master service while updating #{params[:id]} on remote."
            logger.error msg
            flash[:warning] = msg
          else
            flash[:warning] = "An error occured while updating #{params[:id]} remotely: #{result.try(:message)}"
          end
        end
      end
    end

    respond_to do |format|
      if success
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { render :xml  => @person,         :status => :ok }
        format.json { render :json => @person.to_json, :status => :ok }
      else
        status        = @person.status || :unprocessable_entity
        flash[:error] = @person.status_message unless @person.status_message.blank?

        format.html { render :action => 'edit' }
        format.json { render :json   => @person.to_json(:include => :errors), :status => status }
        format.xml  { render :xml    => @person, :status => status }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml 
  def destroy
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end

  def show_remote
    @person = Person.pull_from_master(params[:id]) do |response, request, result|
      case result
      when Net::HTTPNotFound
        respond_to do |format|
          format.html { render :text => 'Record not found!', :status => :not_found }
          format.any  { head :not_found }
        end
      else
        respond_to do |format|
          flash[:error] = 'Remote Service is not available'
          format.html { redirect_to :action => :index }
          format.any  { head :service_unavailable, :retry_after => 60 }
        end
      end
      return
    end

    
    if @person.blank?
      @person = Person.joins(:national_patient_identifier).where(:'national_patient_identifiers.value' => params[:id]).first
    end
    
    respond_to do |format|
      format.html { render :action => 'show' }
      format.json { render :json => @person.to_json }
      format.xml  { render :xml  => @person }
    end
  end

  def send_demographics_to_master
    if Site.proxy?
      people = Person.find(params[:patient_ids].split(','))

      filename = Site.current_code + Time.now().strftime('%Y%m%d%H%M%S') + '.txt'
      `touch #{Rails.root}/demographics/#{filename}`
      l = Logger.new(Rails.root.join("demographics",filename))
      p = []
      people.each do |person|
        l.info "#{person.to_json}"
        p << person.to_json
      end

      batch_info = {}                                                           
                                                                                
      file_info = `cksum #{Rails.root}/demographics/#{filename}`.split(' ')            
      batch_info[:check_sum] = file_info[0]                                     
      batch_info[:file_size] = file_info[1]                                     
      batch_info[:file_name] = filename                                         

      people_params = {'people' => p.to_json}
      people_params.merge!('file' => batch_info)
      people_params.merge!('site_code' => Site.current_code)

      
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/send_demographics_to_master/"
      sync = RestClient.post(uri,people_params)
      render :text => batch_info[:file_name].to_s and return
    else
      site_code = params['site_code'] 
      received_file = params['file']
      filename = received_file['file_name']
      patients = JSON.parse(params['people'])
      
      `touch #{Rails.root}/demographics/#{filename}`
      l = Logger.new(Rails.root.join("demographics",filename))
      patients.each do |person|
        l.info "#{person}"
      end

      batch_info = {}                                                           
                                                                                
      file_info = `cksum #{Rails.root}/demographics/#{filename}`.split(' ')            
      batch_info[:check_sum] = file_info[0]                                     
      batch_info[:file_size] = file_info[1]                                     

      if batch_info[:check_sum].to_i == received_file['check_sum'].to_i
        raise "yes .......... #{batch_info[:check_sum]}" 
      else
        raise "NO ....#{patients.length}...... #{batch_info[:file_size].to_s} >>>>>>>>>>>>>>>> #{received_file['file_size'].to_s}" 
      end

    end
  end

  protected

  def handle_local_conflict(local_person, remote_person)
    @local_person  = local_person
    @remote_person = remote_person

    respond_to do |format|
      format.html { render :action => 'conflict' }
      format.json { render :json => @local_person.to_json, :status => :conflict }
    end
  end

  def handle_remote_conflict(local_person, remote_person)
    @local_person  = local_person
    @remote_person = remote_person
    @local_person.remote_version_number = @remote_person.version_number

    respond_to do |format|
      format.html { render :action => 'conflict' }
      format.json { render :json => @local_person.to_json, :status => :conflict }
    end
  end

  def default_path
    people_path
  end

  def load_person
    @person = Person.find_by_npid_value(params[:id])
    @person ||= Person.find(params[:id]) if Site.proxy?
  rescue ActiveRecord::RecordNotFound
    # noop
  end

end

