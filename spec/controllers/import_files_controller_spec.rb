require 'spec_helper'

describe ImportFilesController do
  before :each do
    session[:user_id] = Factory(:user).id
  end
  
  def mock_import_file(stubs={})
    @mock_import_file ||= mock_model(ImportFile, stubs).as_null_object
  end
  
  describe 'new' do
    it 'should set up an import_file variable for the view' do
      get :new, dataset_description_id: 1
      assigns[:import_file].dataset_description_id.should == 1
    end
  end
  
  describe 'create' do
    it 'should redirect to the preview page when successful' do
      ImportFile.stub(:new) { mock_import_file(save: true) }
      post :create
      response.should redirect_to(preview_import_file_path(mock_import_file.id))
    end
  end
  
end