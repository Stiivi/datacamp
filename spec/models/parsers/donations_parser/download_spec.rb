require 'spec_helper'

class Parsers::DonationsParser::Parser; end

describe Parsers::DonationsParser::Downloader do
  subject { Parsers::DonationsParser::Downloader.new(42, 2011) }
  let(:config) { stub(update_attribute: true, download_path: []) }

  it 'should download the proposal list' do
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:post,
                         "https://registerkultury.gov.sk/granty2011/zobraz_ziadosti.php",
                         body: 'html')

    subject.stub(:get_config).and_return( config )
    Parsers::DonationsParser::Parser.should_receive(:parse).with('html', 2011)

    subject.perform

    File.read(Rails.root.join('data',
                              'test',
                              'registerkultury.gov.sk',
                              'proposals',
                              '2011.html')).should == 'html'
  end

end

