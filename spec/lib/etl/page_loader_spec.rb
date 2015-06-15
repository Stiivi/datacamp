require 'spec_helper'
require 'etl/page_loader'

describe Etl::PageLoader do
  describe '.load_by_get' do
    it 'make get request to given url pass it to page class' do
      MyPageClass = Struct.new(:document)

      VCR.use_cassette('etl/page_loader/executors') do
        page = Etl::PageLoader.load_by_get('http://www.ske.sk/zoznam-exekutorov/', MyPageClass)
        page.should be_instance_of(MyPageClass)
        page.document.should respond_to(:xpath)
      end
    end
  end
end
