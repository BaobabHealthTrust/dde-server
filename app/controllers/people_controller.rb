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
    unless params[:value].blank?
      @people = Person.joins(:national_patient_identifier).where(params.slice(:given_name,
      :family_name, :family_name2,:city_village,
      :gender).merge("national_patient_identifiers.value" => params[:value])).select("people.*,value")

      if @people.blank?
        national_id = params[:value].gsub('-','')
        @people = Person.joins([:national_patient_identifier,
          :legacy_national_ids]).where('legacy_national_ids.value' => national_id).select("people.*,national_patient_identifiers.value")
        people = @people && Person.joins(:legacy_national_ids).where('legacy_national_ids.value' => national_id).
          select("people.*,legacy_national_ids.value")
        @people = []
        people.each do |person|
          @people << JSON.parse(person.to_json)
        end
        # (@ppeeople || []).each do |person|
        #  person.assign_npid if person.national_patient_identifier.blank?
        # end
      end
    else
      #@people = []
      #(Person.search(params) || []).each do |person|
       #   @people << JSON.parse(person.to_json)
      #end
      @people = Person.search(params)
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
        format.json { render :json   => @people.to_json } #, :status => :multiple_choices }
      end
    end
  end

  def find_by_id
    raise params
    person = Person.find_by_id()
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

    version = Guid.new.to_s
    @person = Person.new(params[:person].merge(
                         {:creator_site_id => Site.current_id ,
                         :given_name => params[:person]["data"]["names"]["given_name"] ,
                         :family_name => params[:person]["data"]["names"]["family_name"] ,
                         :gender => params[:person]["data"]["gender"] ,
                         :birthdate => params[:person]["data"]["birthdate"] ,
                         :birthdate_estimated => params[:person]["data"]["birthdate_estimated"],
                         :version_number => version,
                         :remote_version_number => version }
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
      person = (params[:person])
      if Site.master?
        person_data_hash = (person['data'])
      else
        person_data_hash = YAML::load(person['data_as_yaml'])
      end
      person.merge!("given_name" => person_data_hash['names']['given_name'])
      person.merge!("family_name" => person_data_hash['names']['family_name'])
      person.merge!("gender" => person_data_hash['gender'])
      person.merge!("birthdate" => person_data_hash['birthdate'])
      person.merge!("birthdate_estimated" => person_data_hash['birthdate_estimated'])
      success = @person.update_attributes(person) do # this block is only called on conflict
        flash[:error] = "Conflicting versions: new (#{params[:person][:version_number].last(12)}) vs. old (#{@person.version_number.last(12)}). NO changes have been saved!"
        handle_local_conflict(@person, @person.dup.reload) and return
      end
=begin
      #redundant as is handled by syncing
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
=end
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

  def sync_demographics_with_master
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


      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/sync_demographics_with_master/"
      sync = RestClient.post(uri,people_params)

      render :text => "updated master" and return
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
        people = create_from_proxy(patients)
        render :text => "done ..." and return
      else
        raise "NO ....#{patients.length}...... #{batch_info[:file_size].to_s} >>>>>>>>>>>>>>>> #{received_file['file_size'].to_s}"
      end

    end
  end

  def proxy_people_to_sync
    last_updated_date = ProxySync.last_updated_date
    if last_updated_date
      people_ids =  Person.joins(:national_patient_identifier).where("people.updated_at > ?",
        last_updated_date.strftime("%Y-%m-%d %H:%M:%S")).select("people.id").order(:id).map(&:id)
      ProxySync.check_for_valid_start_date unless people_ids.blank?
    else
      people_ids = Person.joins(:national_patient_identifier).select("people.id").order(:id).map(&:id)
      ProxySync.check_for_valid_start_date unless people_ids.blank?
    end
    render :text => people_ids.sort.to_json
  end

  def sync_demographics_with_proxy
    if Site.master?
      people = Person.find(params[:patient_ids].split(','))
      site_code = params[:site_code]
      filename = site_code + Time.now().strftime('%Y%m%d%H%M%S') + 'M.txt'
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
      people_params.merge!('site_code' => site_code)

      render :text => people_params.to_json
    else
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/sync_demographics_with_proxy/"
      params.merge!("site_code" => Site.current_code)
      sync = RestClient.post(uri,params)
      people_params = JSON.parse(sync)
      received_file = people_params['file']
      filename = received_file['file_name']
      patients = JSON.parse(people_params['people'])
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
        people = create_from_master(patients)
        render :text => "updated proxy" and return
      else
        raise "NO ....#{patients.length}...... #{batch_info[:file_size].to_s} >>>>>>>>>>>>>>>> #{received_file['file_size'].to_s}"
      end
    end
  end

  def demographics_to_sync
    if Site.proxy?
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/demographics_to_sync/"
      ids = RestClient.post(uri,{"site_id" => Site.current_id})
      people_ids = JSON.parse(ids)
    else
      site_id = params[:site_id]
      site_code = Site.find_by_id(site_id).code
      last_updated_date = ProxySync.last_updated_date(site_code)
      unless last_updated_date.blank?
        people_ids = Person.find(:all,:conditions => ["creator_site_id != ? 
          AND updated_at > ?",site_id,last_updated_date],
          :order => "id").collect {|p|p.id}
      else
        people_ids = Person.find(:all,:conditions => ["creator_site_id != ?",site_id],
          :order => "id").collect{|p|p.id}
      end
    end 
    render :text => people_ids.sort.to_json
  end
  
  def master_people_to_sync
    if Site.proxy?
      uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/master_people_to_sync/"
      ids = RestClient.post(uri,{"site_id" => Site.current_id})
      render :text =>  ids.to_json and return
    else
      site_id = params[:site_id]
      site_code = Site.find(site_id).code
      last_updated_date = MasterSync.last_updated_date(site_code)
      unless last_updated_date.blank?
        people_ids = Person.where("creator_site_id != ? AND updated_at > ?",
          site_id,last_updated_date.strftime("%Y-%m-%d %H:%M:%S")).select(:id).order(:id).map(&:id)
        if people_ids.blank?
          people_ids = check_if_site_has_sync_before(site_code)
        end
          
        MasterSync.check_for_valid_start_date(site_code) unless people_ids.blank?
      else
        people_ids = Person.where("creator_site_id != ?",site_id).select(:id).order(:id).map(&:id)
        MasterSync.check_for_valid_start_date(site_code) unless people_ids.blank?
      end
      render :text => people_ids.sort.to_json and return
    end
  end

  def record_successful_sync
    if Site.proxy?
      if params[:update_master].blank?
        sync = ProxySync.where("start_date IS NOT NULL AND end_date IS NULL").first
        sync.end_date = DateTime.now()
        sync.save
      elsif not params[:update_master].blank?
        uri = "http://#{dde_master_user}:#{dde_master_password}@#{dde_master_uri}/people/record_successful_sync/"
        RestClient.post(uri,{"site_code" => Site.current_code})
        update_proxy_sync 
      end
    elsif Site.master?
      sync = MasterSync.where("created_date IS NOT NULL 
        AND updated_date IS NULL AND site_code = ?",params[:site_code]).first
      sync.updated_date = DateTime.now()
      sync.save
    end
    render :text => 'done ...' and return
  end

  def replace_national_id
    national_id = params[:identifier]
    given_name = params[:given_name]
    family_name = params[:family_name]
    gender = params[:gender]
    person_id = Person.joins(:national_patient_identifier).
             where("national_patient_identifiers.value" => national_id,
                   "national_patient_identifiers.voided" => 0,
                   "given_name" => given_name,"family_name" => family_name,
                   "gender" => gender).select("people.id")
    render :text => {}.to_json if person_id.blank? and return
    
    national_id = NationalPatientIdentifier.find_by_person_id(person_id)
    national_id.voided = 1
    national_id.void_reason = "Assigned new National Identifier"
    national_id.voided_date = Time.now()
    person = Person.find_by_id(person_id)
    national_id = person.assign_npid
    person.save
    render :text => national_id.value.to_json unless national_id.blank? and return
    render :text => {}.to_json and return
   end

  protected

  def check_if_site_has_sync_before(site_code)
    sync = MasterSync.where(:'site_code' => site_code)
    if sync.blank?
      creator_site_id = Site.where(:'code' => site_code).first.id
      return Person.where('creator_site_id <> ?', 
        creator_site_id).select(:id).map(&:id)
    end
    return []
  end

  def update_proxy_sync
    last_updated_date = ProxySync.last_updated_date
    max_person_updated_date = Person.maximum(:created_at)
    ProxySync.create(:start_date => last_updated_date, 
      :end_date => max_person_updated_date)
  end

  def update_sync_transaction
    sync = ProxySync.new()
    sync.sync_site_id = site_code
    sync.last_person_id = people.last.id
    sync.created_date = last_created_time
    sync.updated_date = last_updated_time
    sync.save
  end

  def create_from_proxy(people)
    created_people = []
    (people).each do |person|
      person_obj = JSON.parse(person)
      if person_obj['npid'].blank?
        logger = Logger.new(Rails.root.join("log",'syncing_error.txt'))
        logger.error "#{person_obj['person']['data']['names']['family_name']},
                      #{person_obj['person']['data']['names']['given_name']},
                      #{person_obj['person']['data']['gender']}"
        next
      end
      person_hash = {'person' => {"family_name" => person_obj['person']['data']['names']['family_name'],
                                  "given_name" => person_obj['person']['data']['names']['given_name'],
                                  "gender" => person_obj['person']['data']['gender'],
                                  "birthdate" => person_obj['person']['data']['birthdate'],
                                  "birthdate_estimated" => person_obj['person']['data']['birthdate_estimated'],
                                  "data" => person_obj['person']['data'],
                                  "creator_site_id" => person_obj['npid']['assigner_site_id'],
                                  "creator_id" => person_obj['person']['creator_id'],
                                  "version_number" => person_obj['person']['version_number'],
                                  "remote_version_number" => person_obj['person']['remote_version_number']}}

      npid_hash = {'npid' => {"value" => person_obj['npid']['value'],
                              "assigner_site_id" => person_obj['person']['creator_site_id'],
                              "assigned_at" => person_obj['npid']["assigned_at"] }}
                    
      site_hash = {'site' => {"id" => person_obj['person']['creator_site_id'] }}

      legacy_ids =  person_obj['legacy_ids'] rescue nil

      person_hash.merge!npid_hash

      person_hash.merge!site_hash

      @person = Person.find_or_initialize_from_attributes(person_hash.slice('person', 'npid', 'site'))
      if @person.save
       (legacy_ids || []).each  do |legacy_id|
         LegacyNationalIds.find_or_create_by_value_and_person_id(:value => legacy_id,:person_id => @person.id)
       end

        NationalIdSite.find_or_create_by_national_id_and_site_id(:national_id => person_obj['npid']['value'],
                               :site_id => person_obj['person']['creator_site_id'])
         created_people << @person
      end
    end
    return created_people
  end

  def create_from_master(people)
    saved_people = []
    (people).each do |person|
      person_obj = JSON.parse(person)
      person_hash = {'person' => {"family_name" => person_obj['person']['data']['names']['family_name'],
                                  "given_name" => person_obj['person']['data']['names']['given_name'],
                                  "gender" => person_obj['person']['data']['gender'],
                                  "birthdate" => person_obj['person']['data']['birthdate'],
                                  "birthdate_estimated" => person_obj['person']['data']['birthdate_estimated'],
                                  "data" => person_obj['person']['data'],
                                  "creator_site_id" => person_obj['npid']['assigner_site_id'],
                                  "creator_id" => person_obj['person']['creator_id'],
                                  "version_number" => person_obj['person']['version_number'],
                                  "remote_version_number" => person_obj['person']['remote_version_number']}}

      npid_hash = {'npid' => {"value" => person_obj['npid']['value'],
                              "assigner_site_id" => person_obj['npid']['assigner_site_id'],
                              "assigned_at" => person_obj['npid']["assigned_at"] }}

      site_hash = {'site' => {"id" => person_obj['npid']['assigner_site_id'] }}

      legacy_ids = person_obj['legacy_ids'] rescue nil
      
      person_hash.merge!npid_hash

      person_hash.merge!site_hash

      @person = Person.find_or_initialize_from_attributes(person_hash.slice('person', 'npid', 'site'))
      if @person.save
        (legacy_ids || []).each  do |legacy_id|
         LegacyNationalIds.find_or_create_by_value_and_person_id(:value => legacy_id,:person_id => @person.id)
       end
        saved_people << @person
      end
    end
    return saved_people
  end

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

