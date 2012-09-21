=begin
Hereafter will be defined the structures to be used when dealing with demographics data within the BART/DDE/Maternity/... ecosystem. Using the same structure in all places will save a lot of code and introduces certain naming conventions that in turn reduce the probability of errors and mistakes in processing them.

Notes:
* the PARAMS structure has to be used in POST requests from a client to a server.
* the DDE_RESPONSE structrure has to be used in (responses to) ANY request to/from Master/Proxy
* the BART_RESPONSE structure has to be used in responses to GET requests inside BART/Maternity
* all the given structures provide the minimum set of keys that MUST be present, unless marked as optional. More keys may be added as needed.
* the same structure is to be used regardles of request/respone format, be it JSON, XML or HTML Form serialisation.
* within ruby code, all keys are expected to be accessible as Strings at any time. This does not affect in any way the possibility to access them as symbols within the Rails params Hash (which is technically an ActiveSupport::HashWithIndifferentAccess), wich should however not be relied upon.
=end

ADDRESS = {
  'address1'        => String,
  'address2'        => String,
  'city_village'    => String,
  'county_district' => String
}

NAMES = {
  'given_name'   => String,
  'family_name'  => String,
  'family_name2' => String  ## Optional (nee name?)
}

DATE = {
  'day'   => Integer,
  'month' => Integer,  ## 1-12
  'year'  => Integer   ## YYYY
}

PARAMS = {
  'gender'       => String, # 'Female'|'Male'
  'age_estimate' => Integer,       ## Remove
  'birth_date'   => DATE,   
  'birtdate_estimated' => Boolean, ## 0|1  Add
  'names'        => NAMES,
  'addresses'    => [ADDRESS],
  'attributes'   => {
    'occupation'          => String,
    'cell_phone_number'   => String,
    'home_phone_number'   => String, # optional
    'office_phone_number' => String, # optional
    # ...
  },
  'identifiers'  => {
    'National Id' => String,
    'ARV Number'  => String, # optional ## Remove??
    # ...
  }
}

NATIONAL_PATIENT_ID = {
  'value'            => String,
  'assigned_at'      => DateTime,
  'assigner_site_id' => Integer
}

SITE = {
  'id'          => Integer,
  'code'        => String, ## e.g. LLH  Add
  'name'        => String,
  'annotations' => String
}

DDE_PARAMS = {
  'person' => {
    'data'            => PARAMS,
    'version_number'  => Integer,
    'created_at'      => DateTime,
    'updated_at'      => DateTime,
    'creator_site_id' => Integer
  },
  'npid'   => NATIONAL_PATIENT_ID, # optional, depending on use case
  'site'   => SITE                 # optional, depending on use case
}

DDE_RESPONSE = {
  'person' => PARAMS,
  'npid'   => NATIONAL_PATIENT_ID,
  'site'   => SITE
}

BART_RESPONSE = PARAMS

