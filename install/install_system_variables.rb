puts "=> Installing system variables and default values ..."

system_variables = [
  {:name => "theme",
   :description => "Theme",
   :value => "default"
  },
  {
    :name => "site_name",
    :description => "Site Name",
    :value => "Datacamp Site"
  },
  {
    :name => "default_import_format",
    :description => "Default import format",
    :value => "csv"
  }
]

system_variables.each do |var|
  var_obj = SystemVariable.find_or_create_by_name(var[:name])
  var_obj.update_attributes(var)
end