# -*- encoding : utf-8 -*-
require "test_helper"

class FieldDescriptionsControllerTest < ActionController::TestCase
  fixtures :dataset_descriptions
  fixtures :dataset_description_translations
  fixtures :field_descriptions
  fixtures :field_description_translations

  ####################################################################################
  # field descriptions/new
  
  test "should load new form" do
    get :new, :dataset_description_id => dataset_descriptions(:articles).to_param
    assert_response :success
    assert_select "form#new_field_description"
  end
  
  test "should load new form with ajax" do
    get :new, :format => 'js', :dataset_description_id => dataset_descriptions(:articles).to_param
    assert_response :success
  end
  
  
  ####################################################################################
  # field descriptions/create
  
  test "should create new field description" do
    assert_difference 'FieldDescription.count' do
      post :create, :dataset_description_id => dataset_descriptions(:articles).to_param, :field_description => {:identifier => 'description',
                                                                                      :data_type_id => data_types(:integer).id,
                                                                                      :en => {:category => 'main',
                                                                                              :title => 'Description',
                                                                                              :description => 'Description of an article'}}
    end
  end
  
  test "should create new field description with ajax" do
    assert_difference 'FieldDescription.count' do
      post :create, :format => 'js', :dataset_description_id => dataset_descriptions(:articles).to_param, :field_description => {:identifier => 'description',
                                                                                      :data_type_id => data_types(:integer).id,
                                                                                      :en => {:category => 'main',
                                                                                              :title => 'Description',
                                                                                              :description => 'Description of an article'}}
    end
  end
  
  
  ####################################################################################
  # field descriptions/edit
  
  test "should load edit form" do
    get :edit, :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param
    assert_response :success
    assert_select "form#edit_field_description_#{field_descriptions(:articles_title).id}"
  end
  
  test "should load edit form with ajax" do
    get :edit, :format => 'js', :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param
    assert_response :success
  end
  
  
  ####################################################################################
  # field descriptions/update
  
  test "should update field description" do
    put :update, :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param, :field_description => {:en => {:title => 'Title 2'}}
    assert_equal "Title 2", field_descriptions(:articles_title).reload.title
  end
  
  test "should update field description with ajax" do
    put :update, :format => 'js', :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param, :field_description => {:en => {:title => 'Title 2'}}
    assert_equal "Title 2", field_descriptions(:articles_title).reload.title
  end
  
  
  ####################################################################################
  # field descriptions/destroy
  
  test "should destroy dataset_description field description" do
    assert_difference 'FieldDescription.count', -1 do
      delete :destroy, :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param
    end
  end
  
  test "should destroy dataset_description field description with ajax" do
    assert_difference 'FieldDescription.count', -1 do
      delete :destroy, :format => 'js', :dataset_description_id => dataset_descriptions(:articles).to_param, :id => field_descriptions(:articles_title).to_param
    end
  end
end
