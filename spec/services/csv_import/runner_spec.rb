require 'spec_helper'

describe CsvImport::Runner do
  let(:name_csv_file_path) { Rails.root.join('spec', 'files', 'names_example.csv') }
  let(:empty_file_path) { Rails.root.join('spec', 'files', 'empty_file_example.csv') }
  let(:missing_row_path) { Rails.root.join('spec', 'files', 'missing_row_example.csv') }
  let(:invalid_row_path) { Rails.root.join('spec', 'files', 'invalid_row_example.csv') }

  let!(:dataset_description) { FactoryGirl.create(:dataset_description, en_title: 'doctors', with_dataset: true) }
  let!(:first_name_column) { FactoryGirl.create(:field_description, en_title: 'First name', identifier: 'first_name', dataset_description: dataset_description) }
  let!(:last_name_column) { FactoryGirl.create(:field_description, en_title: 'Last name', identifier: 'last_name', dataset_description: dataset_description) }

  let(:user) { FactoryGirl.create(:user) }

  let(:column_mapping) { {'0' => first_name_column.id.to_s, '1' => last_name_column.id.to_s} }

  after(:each) do
    Dir.glob("#{Rails.root}/files/*_example.csv").each do |filepath|
      File.delete(filepath)
    end
  end

  def create_import_file(file_path, dataset_description)
    import_file = nil
    File.open(file_path) do |file|
      import_file = ImportFile.create!(dataset_description_id: dataset_description.id, path: file, file_template: ImportFile::CSV_TEMPLATE[:id])
    end
    import_file
  end

  def csv_file(import_file)
    CsvFile.new(
        import_file.file_path,
        import_file.col_separator,
        import_file.encoding,
        import_file.skip_first_line?,
        import_file.has_header?
    )
  end

  def runner(import_file, dataset_description, mapping, user)
    CsvImport::Runner.new(
        csv_file(import_file),
        CsvImport::Record.new(
            dataset_description.dataset_model,
            CsvImport::Mapper.new(mapping, dataset_description.field_descriptions(true)),
            import_file
        ),
        CsvImport::Listener.new(import_file, Change, current_user: user),
        CsvImport::Interceptor.new(import_file)
    )
  end

  describe '#run' do
    it 'imports file to database' do
      import_file = create_import_file(name_csv_file_path, dataset_description)

      runner(import_file, dataset_description, column_mapping, user).run

      import_file.status.should eq 'success'
      import_file.count_of_imported_lines.should eq 3
      dataset_description.dataset_model.count.should eq 3

      dataset_description.dataset_model.all.each do |record|
        record.record_status.should eq 'new'
        record.batch_id.should eq import_file.id
      end

      dataset_description.dataset_model.pluck(:first_name).should eq ['ján', 'matúš', 'dominik']
      dataset_description.dataset_model.pluck(:last_name).should eq ['veľký', 'malý', 'pekný']

      Change.last.change_details[:update_conditions][:_record_id].should eq dataset_description.dataset_model.pluck(:_record_id)
    end

    it 'should not fail when csv file is empty' do
      import_file = create_import_file(empty_file_path, dataset_description)

      runner(import_file, dataset_description, column_mapping, user).run

      import_file.status.should eq 'failed'
    end

    it 'does not skip empty lines from csv' do
      import_file = create_import_file(missing_row_path, dataset_description)
      runner(import_file, dataset_description, column_mapping, user).run

      import_file.status.should eq 'success'
      dataset_description.dataset_model.count.should eq 3
    end

    it 'does not ignore invalid rows' do
      import_file = create_import_file(invalid_row_path, dataset_description)
      runner(import_file, dataset_description, column_mapping, user).run

      import_file.status.should eq 'success'
      dataset_description.dataset_model.count.should eq 4
    end

    it 'is possible to change mapping' do
      import_file = create_import_file(name_csv_file_path, dataset_description)
      runner(import_file, dataset_description, {'0' => last_name_column.id.to_s}, user).run

      dataset_description.dataset_model.pluck(:last_name).should eq ['ján', 'matúš', 'dominik']
    end
  end
end