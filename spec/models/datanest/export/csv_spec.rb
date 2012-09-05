require File.expand_path(File.dirname(__FILE__) + '../../../../../app/models/datanest/export/csv')

class DatasetDescription; end

describe Datanest::Export::Csv do

  let(:fields_for_export) { [1,2,3] }
  let(:output) { stub }
  subject { Datanest::Export::Csv.new(fields_for_export, output) }

  before(:each) { CSV.stub(generate_line: [1,2,3]) }

  it 'should write the header' do
    subject.should_receive(:write_line).with(output, [1,2,3])
    subject.write_header
  end

  it 'should write records' do
    record = mock
    record.should_receive(:formatted_values_for_fields).with([1,2,3]).and_return([1,2,3])

    subject.should_receive(:write_line).with(output, [1,2,3])
    subject.write_records([record])
  end

  it 'should write a line of csv' do
    output.should_receive(:write).with([1,2,3])
    subject.write_line(output, stub)
  end
end
