require 'test_helper'

class DatasetDescriptionsControllerTest < ActionController::TestCase
  fixtures :dataset_descriptions
  fixtures :dataset_description_translations
  
  ####################################################################################
  # dataset_descriptions/index
  
  test "should show group of the dataset_description" do
    get :index
    assert_response :success
    assert_select "table.dataset_descriptions tr.title td", dataset_descriptions(:articles).category
  end
  
  test "should list dataset_descriptions" do
    get :index
    assert_response :success
    assert_equal 1, assigns(:dataset_descriptions).size
  end
  
  test "should link to show action" do
    get :index
    assert_response :success
    assert_select "table.dataset_descriptions tr td a[href=#{dataset_description_url(dataset_descriptions(:articles))}]", dataset_descriptions(:articles).title
  end
  
  
  ####################################################################################
  # dataset_descriptions/show
  
  test "should show dataset_description information" do
    get :show, :id => dataset_descriptions(:articles).to_param
    assert_response :success
    assert_not_nil assigns(:dataset_description)
    assert_select "h1", dataset_descriptions(:articles).title
    assert_select "p.description", dataset_descriptions(:articles).description
  end
  
  test "should load dataset_description with ajax" do
    get :show, :format => 'js', :id => dataset_descriptions(:articles).to_param
    assert_response :success
  end
  
  test "should list field descriptions" do
    get :show, :id => dataset_descriptions(:articles).to_param
    assert_response :success
    assert_not_nil assigns(:dataset_description)
        
    # assert_select "li.section div.title"
    assert_select "li#field_description_#{field_descriptions(:articles_title).id}"
  end
  
  test "should list relationship descriptions" do
    get :show, :id => dataset_descriptions(:articles).to_param
    assert_response :success
    assert_not_nil assigns(:dataset_description).relationship_descriptions, "relationship_descriptions field_description of dataset_description was null"
    assert_equal 1, assigns(:dataset_description).relationship_descriptions.size, "number of relationship_descriptions for dataset_description was not 1"
    
    assert_select "li#relationship_description_#{dataset_descriptions(:articles).relationship_descriptions[0].id}"
  end
  
  
  ####################################################################################
  # dataset_descriptions/new
  
  test "should show new form for dataset_description" do
    get :new
    assert_response :success
    assert_select "form#new_dataset_description.new_dataset_description"
  end
  
  
  ####################################################################################
  # dataset_descriptions/create
  
  test "should create dataset_description" do
    assert_difference 'DatasetDescription.count' do
      post :create, :dataset_description => {:database => 'main',
                                :identifier => 'users',
                                :en => {:category => 'main',
                                        :title => 'Users',
                                        :description => 'All the users'}}
    end
    assert_not_nil assigns(:dataset_description)
    assert assigns(:dataset_description).valid?
    assert_redirected_to dataset_description_path(assigns(:dataset_description))
  end
  
  
  ####################################################################################
  # dataset_descriptions/edit
  
  test "should show edit form for dataset_description" do
    get :edit, :id => dataset_descriptions(:articles).to_param
    assert_response :success
    assert_select "form#edit_dataset_description_#{dataset_descriptions(:articles).id}.edit_dataset_description"
  end

  
  ####################################################################################
  # dataset_descriptions/update
  
  test "should update dataset_descriptions field_descriptions" do
    put :update, :id => dataset_descriptions(:articles).to_param, :dataset_description => {:en => {:title => 'Articles X'}}
    assert_not_nil assigns(:dataset_description)
    assert_redirected_to dataset_description_path(assigns(:dataset_description))
  end
  
  
  ####################################################################################
  # dataset_descriptions/destroy
  
  test "should destroy dataset_description" do
    assert_difference 'DatasetDescription.count', -1 do
      delete :destroy, :id => dataset_descriptions(:articles).to_param
    end
  end
end
