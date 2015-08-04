require_relative '../../../app/services/csv_import/mapper'

describe CsvImport::Mapper do

  describe '#build_attributes' do

    let(:first_name) { double(:first_name, id: 5, identifier: 'first_name') }
    let(:last_name) { double(:last_name, id: 9, identifier: 'last_name') }

    it 'build attributes hash' do
      field_descriptions = [first_name, last_name]

      attributes = CsvImport::Mapper.new(
          {
              '0' => first_name.id,
              '1' => last_name.id,
          },
          field_descriptions
      ).build_attributes(['John', 'Newman'])

      attributes.should eq ({
                               'first_name' => 'John',
                               'last_name' => 'Newman',
                           })
    end

    it 'skips given value if column mapping is wrong' do
      field_descriptions = [first_name, last_name]

      attributes = CsvImport::Mapper.new(
          {
              '0' => 22,
              '1' => last_name.id,
          },
          field_descriptions
      ).build_attributes(['John', 'Newman'])

      attributes.should eq ({
                               'last_name' => 'Newman',
                           })
    end

    it 'ignores values that are not in mapping' do
      field_descriptions = [first_name, last_name]

      attributes = CsvImport::Mapper.new(
          {
              '0' => first_name.id,
              '1' => last_name.id,
          },
          field_descriptions
      ).build_attributes(['John', 'Newman', 'The second'])

      attributes.should eq ({
                               'first_name' => 'John',
                               'last_name' => 'Newman',
                           })
    end
  end


end