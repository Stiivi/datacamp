require 'spec_helper'

describe ApiController do
  before {controller.stub(:authorize_api_key)}

  it 'should fetch changes' do
    changes = stub(to_xml: 'this is xml')
    dataset = stub(fetch_changes: changes, identifier: 'xxx')
    controller.stub(:find_dataset).and_return(dataset)
    get :dataset_changes, format: :xml
    response.body.should == changes.to_xml
  end

end
