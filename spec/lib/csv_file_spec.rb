# -*- encoding : utf-8 -*-
require 'spec_helper'

describe CsvFile do

  it 'should mark a valid csv as valid' do
    csv_importer = CsvFile.new(Rails.root.join('spec', 'files', 'valid_csv_example.csv'), ',', 'utf-8')
    csv_importer.is_valid?.should be_true
  end
  
  it 'should mark an invalid csv as invalid' do
    csv_importer = CsvFile.new(Rails.root.join('spec', 'files', 'header.xls'), ';', 'utf-8')
    csv_importer.is_valid?.should be_false
  end
  
  it 'should read the header' do
    csv_importer = CsvFile.new(Rails.root.join('spec', 'files', 'valid_csv_example.csv'), ',', 'utf-8', false, true)
    csv_importer.header.should == ["_record_id", "firma_deklaranta", "titul_deklaranta", "meno_deklaranta", "priezvisko_deklaranta", "ico", "adresa", "psc", "mesto", "paragraf", "celkova_odpustena_suma", "mena", "rok", "colny_urad", "poznamka", "poznamka2"]
  end
  
  it 'should read the sample' do
    csv_importer = CsvFile.new(Rails.root.join('spec', 'files', 'valid_csv_example.csv'), ',', 'utf-8', false, true)
    csv_importer.sample.should == ["1", "", "", "", "Prokopovič", "", "", "", "", "", "15930", "Sk", "2003", "Fiľakovo", "", ""]
  end
  
  it 'should parse all lines' do
    csv_importer = CsvFile.new(Rails.root.join('spec', 'files', 'valid_csv_example.csv'), ',', 'utf-8', false, true)
    rows = []
    csv_importer.parse_all_lines { |row| rows << row }
    rows.should == [["1", "", "", "", "Prokopovič", "", "", "", "", "", "15930", "Sk", "2003", "Fiľakovo", "", ""], ["2", "Total Sport", "", "", "", "36010634", "", "", "", "", "16112", "Sk", "2003", "Fiľakovo", "", ""], ["3", "CSM Tisovec", "", "", "", "31561888", "", "", "", "", "1409", "Sk", "2003", "Fiľakovo", "", ""]]
  end
  
end