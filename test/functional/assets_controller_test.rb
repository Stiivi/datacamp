require 'test_helper'

class AssetsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create asset" do
    assert_difference('Asset.count') do
      post :create, :asset => { :dataset_description_id => dataset_descriptions(:articles).id }
    end

    assert_redirected_to asset_path(assigns(:asset))
  end

  test "should show asset" do
    get :show, :id => assets(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => assets(:one).to_param
    assert_response :success
  end

  test "should update asset" do
    put :update, :id => assets(:one).to_param, :asset => { :dataset_description_id => dataset_descriptions(:articles).id }
    assert_redirected_to asset_path(assigns(:asset))
  end

  test "should destroy asset" do
    assert_difference('Asset.count', -1) do
      delete :destroy, :id => assets(:one).to_param
    end

    assert_redirected_to assets_path
  end
  
  test "should not create asset without an dataset_description_id" do
    # TODO
  end
end
