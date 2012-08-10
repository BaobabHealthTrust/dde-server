class NationalPatientIdentifiersController < ApplicationController
  # GET /national_patient_identifiers
  # GET /national_patient_identifiers.xml
  def index
    @national_patient_identifiers = NationalPatientIdentifier.page(params[:page]
                                                                  ).all(:include => :assigner_site) 

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

  def for_site
    @site = Site.find_by_code params[:site_id]
    @national_patient_identifiers = @site.national_patient_identifiers.all :include => :assigner_site

    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @national_patient_identifiers }
    end
  end

  # GET /national_patient_identifiers/new
  # GET /national_patient_identifiers/new.xml
  def new
    redirect_to new_npid_request_path
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
