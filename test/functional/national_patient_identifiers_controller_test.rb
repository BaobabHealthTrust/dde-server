require 'test_helper'

class NationalPatientIdsControllerTest < ActionController::TestCase
  setup do
    @national_patient_id = national_patient_ids(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:national_patient_ids)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create national_patient_id" do
    assert_difference('NationalPatientId.count') do
      post :create, :national_patient_id => @national_patient_id.attributes
    end

    assert_redirected_to national_patient_id_path(assigns(:national_patient_id))
  end

  test "should show national_patient_id" do
    get :show, :id => @national_patient_id.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @national_patient_id.to_param
    assert_response :success
  end

  test "should update national_patient_id" do
    put :update, :id => @national_patient_id.to_param, :national_patient_id => @national_patient_id.attributes
    assert_redirected_to national_patient_id_path(assigns(:national_patient_id))
  end

  test "should destroy national_patient_id" do
    assert_difference('NationalPatientId.count', -1) do
      delete :destroy, :id => @national_patient_id.to_param
    end

    assert_redirected_to national_patient_ids_path
  end
end
