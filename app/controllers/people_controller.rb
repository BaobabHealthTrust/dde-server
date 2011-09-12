class PeopleController < ApplicationController

  before_filter :load_person,
      :only => [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.xml
  def index
    @people = Person.all

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
    @people = Person.where params.slice(:given_name, :family_name, :family_name2, :city_village, :gender)

    case @people.size
    when 0
      if SITE_CONFIG[:mode] == 'master'
        head :not_found
      else
        find_remote
      end
    when 1
      respond_to do |format|
        format.html # show.html.erb
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
    @person = Person.new(params[:person])

    respond_to do |format|
      if @person.save
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
    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.html { redirect_to(@person, :notice => 'Person was successfully updated.') }
        format.any  { head :ok }
      else
        status = @person.errors.delete(:status) || :unprocessable_entity

        format.html { render :action => 'edit' }
        format.xml  { render :xml  => @person.errors, :status => status }
        format.json { render :json => @person.errors, :status => status }
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
    logger.info "fetching from remote: #{params[:id]}"
    @person = Person.find_remote(params[:id]) do |response, request, result|
      case result
      when Net::HTTPNotFound
        respond_to do |format|
          format.html { render :text => 'Record not found!', :status => :not_found }
          format.any  { head :not_found }
        end
        return
      else
        head :service_unavailable, :retry_after => 60 and return
      end
    end

    @person.save!

    respond_to do |format|
      format.html { render :action => 'show' }
      format.json { render :json => @person.to_json }
      format.xml  { render :xml  => @person }
    end
  end

  def find_remote
    raise NotImplementedError
  end

  protected
  def default_path
    people_path
  end

  def load_person
    @person = Person.includes(:national_patient_identifier).where(:'national_patient_identifiers.value' => params[:id]).first
    if Site.proxy?
      @person ||= Person.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    # noop
  end

end
