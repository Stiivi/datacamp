When /^I upload a new file$/ do
  visit(new_import_file_path)
  attach_file('File', Rails.root.join('features', 'files_for_upload', 'test.csv'))
  fill_in('Col separator', with: ';')
  click_button('Continue')
end

Then /^columns should be matched based what is in the file header$/ do
  field = find_field('column[0]')
  field.native.xpath(".//option[@selected = 'selected']").inner_html.should =~ /sk title/
end

When /^I start an import$/ do
  When %{I upload a new file}
  click_button('Import')
end