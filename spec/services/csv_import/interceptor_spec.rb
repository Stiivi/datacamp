require_relative '../../../app/services/csv_import/interceptor'

describe CsvImport::Interceptor do
  let(:import_file) {
    import_file = double(:import_file)
    import_file.stub(:reload) { import_file }
    import_file
  }

  describe '#intercept' do
    it 'raises InterceptSignal error if import_file status changed to canceled' do
      import_file.stub(:status).and_return('canceled')

      subject = CsvImport::Interceptor.new(import_file, 1)

      expect {
        subject.intercept
      }.to raise_error(CsvImport::InterceptSignal)
    end

    it 'does not raise error if status of import_file does not changed' do
      import_file.stub(:status).and_return('ok')

      subject = CsvImport::Interceptor.new(import_file, 1)

      expect {
        subject.intercept
      }.not_to raise_error
    end

    it 'checks import_file for changes only in given checking_delay' do
      import_file.should_receive(:status).exactly(1).times

      subject = CsvImport::Interceptor.new(import_file, 2)
      subject.intercept
      subject.intercept
    end
  end
end