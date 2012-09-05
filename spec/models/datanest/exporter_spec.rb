require File.expand_path(File.dirname(__FILE__) + '../../../../app/models/datanest/exporter')

class DatasetDescription; end

describe Datanest::Exporter do

  its(:strategy) { should == :csv }
  let(:datasets) { [stub(identifier: 'hockey'), stub(identifier: 'soccer')] }

  it 'takes an input strategy parameter' do
    subject = Datanest::Exporter.new(strategy: :xml)
    subject.strategy.should == :xml
  end

  describe 'export workspace preparation' do
    before :each do
      subject.stub(:export_path).and_return('some/path')
      File.stub(:exist?).and_return(false)
    end
    it 'creates the output folder if it does not exist' do
      FileUtils.should_receive(:mkdir).with('some/path')
      subject.prepare_workspace
    end
    it 'does not try to create the output folder if it exists' do
      File.stub(:exist?).and_return(true)
      FileUtils.should_not_receive(:mkdir)
      subject.prepare_workspace
    end
  end

  it 'prepares the workspace and exports all datasets' do
    subject.stub(:datasets).and_return(datasets)
    subject.should_receive(:prepare_workspace)
    datasets.each {|sd| subject.should_receive(:export_dataset).with(sd) }
    subject.export
  end

  it 'exports a dataset' do
    columns = [stub]
    file = stub
    dataset = stub
    dataset.stub(:each_published_records).and_yield([[1,2,3]])

    dumper_klass = stub
    subject.stub(:dumper_klass).and_return(dumper_klass)

    dumper_instance = mock
    dumper_klass.should_receive(:new).with(columns, file).and_return(dumper_instance)

    dumper_instance.should_receive(:write_header)
    dumper_instance.should_receive(:write_records).with([[1,2,3]])

    subject.should_receive(:gather_columns).with(dataset).and_return(columns)
    subject.should_receive(:open_file).with(dataset).and_yield(file)
    subject.export_dataset(dataset)
  end
end


