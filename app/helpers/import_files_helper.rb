module ImportFilesHelper
  def field_description_picker column
    selected_field = @mapping[column]
    
    select_tag "column[#{column}]", options_for_select([nil] + @import_file.dataset_description.field_descriptions.map{|fd|[fd.title, fd.id]}, selected_field)
  end
end
