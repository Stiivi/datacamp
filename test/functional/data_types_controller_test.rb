require 'test_helper'

class DataTypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_type" do
    assert_difference('DataType.count') do
      post :create, :data_type => { }
    end

    assert_redirected_to data_types_path
  end

  test "should get edit" do
    get :edit, :id => data_types(:one).to_param
    assert_response :success
  end

  test "should update data_type" do
    put :update, :id => data_types(:one).to_param, :data_type => { }
    assert_redirected_to data_types_path
  end

  test "should destroy data_type" do
    assert_difference('DataType.count', -1) do
      delete :destroy, :id => data_types(:one).to_param
    end

    assert_redirected_to data_types_path
  end
end
