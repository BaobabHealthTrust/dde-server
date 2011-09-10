class NationalPatientIdentifiersController < ApplicationController
  # GET /national_patient_identifiers
  # GET /national_patient_identifiers.xml
  def index
    @national_patient_identifiers = NationalPatientIdentifier.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @national_patient_identifiers }
    end
  end

  # GET /national_patient_identifiers/1
  # GET /national_patient_identifiers/1.xml
  def show
    @national_patient_identifier = NationalPatientIdentifier.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @national_patient_identifier }
    end
  end

  # GET /national_patient_identifiers/new
  # GET /national_patient_identifiers/new.xml
  def new
    if Site.master?
      @national_patient_identifier = NationalPatientIdentifier.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @national_patient_identifier }
      end
    else
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { head :not_implemented }
      end
    end
  end

  # GET /national_patient_identifiers/1/edit
  def edit
    @national_patient_identifier = NationalPatientIdentifier.find(params[:id])
  end

  # POST /national_patient_identifiers
  # POST /national_patient_identifiers.xml
  def create
    @national_patient_identifier = NationalPatientIdentifier.new(params[:national_patient_id])

    respond_to do |format|
      if @national_patient_identifier.save
        format.html { redirect_to(@national_patient_identifier, :notice => 'National patient was successfully created.') }
        format.xml  { render :xml => @national_patient_identifier, :status => :created, :location => @national_patient_identifier }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @national_patient_identifier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /national_patient_identifiers
  def generate
    if Site.master?
      if params[:last_timestamp]
        if params[:last_timestamp].blank?
          generated_but_not_sent_ids = NationalPatientIdentifier.where(:assigned_at => nil)
        else
          generated_but_not_sent_ids = NationalPatientIdentifier.where(['created_at > ?', params[:last_timestamp]])
          number_of_needed_ids = params[:npid][:count].to_i - generated_but_not_sent_ids.count
          if number_of_needed_ids > 0
            params[:npid][:count] = number_of_needed_ids
          end
          NationalPatientIdentifier.generate! params[:npid]
        end
        @npids = generated_but_not_sent_ids.reload.all
      else
        @npids = NationalPatientIdentifier.generate! params[:npid]
      end
    else
      @npids = NationalPatientIdentifier.request! params[:npid].merge(:assigner_site_id => Site.current_id)
    end

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.json { render :json => @npids.to_json, :status => :created }
      format.xml  { render :xml  => @npids, :status => :created }
    end
  end

  # PUT /national_patient_identifiers/1
  # PUT /national_patient_identifiers/1.xml
  def update
    @national_patient_identifier = NationalPatientIdentifier.find(params[:id])

    respond_to do |format|
      if @national_patient_identifier.update_attributes(params[:national_patient_id])
        format.html { redirect_to(@national_patient_identifier, :notice => 'National patient was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @national_patient_identifier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /national_patient_identifiers/1
  # DELETE /national_patient_identifiers/1.xml
  def destroy
    @national_patient_identifier = NationalPatientIdentifier.find(params[:id])
    @national_patient_identifier.destroy

    respond_to do |format|
      format.html { redirect_to(national_patient_identifiers_url) }
      format.xml  { head :ok }
    end
  end
end
