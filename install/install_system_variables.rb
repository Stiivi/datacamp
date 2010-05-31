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
  },
  {
    :name => "login_required",
    :description => "Login required to use application",
    :value => 1
  },
  {
    :name => "copyright_notice",
    :description => "Copyright notice displayed in the footer.",
    :value => "&copy; Your Comapny"
  },
  {
    :name => "private_mode",
    :description => "Users can't register, only subscribe for beta program.",
    :value => 1
  },
  {
    :name => "registration_confirmation_required",
    :description => "Users need their accounts confirmed by admin before being able to use them.",
    :value => 0
  }
]

system_variables.each do |var|
  unless SystemVariable.find_by_name(var[:name])
    SystemVariable.create(var)
  end
end