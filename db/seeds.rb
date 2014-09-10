# -*- encoding : utf-8 -*-
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alonge the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

require 'dataset/utils'

EtlConfiguration.find_or_create_by_name('vvo_extraction', start_id: 2642, batch_limit: 1000)
EtlConfiguration.find_or_create_by_name('notary_extraction', start_id: 1, batch_limit: 100)
EtlConfiguration.find_or_create_by_name('executor_extraction')
EtlConfiguration.find_or_create_by_name('lawyer_extraction')
EtlConfiguration.find_or_create_by_name('donations_parser', parser: true)
EtlConfiguration.find_or_create_by_name('otvorenezmluvy_extraction', start_id: 201110)
EtlConfiguration.find_or_create_by_name('foundation_extraction')
EtlConfiguration.find_or_create_by_name('mzvsr_contracts_extraction')

# Initialize datasets and relations

# Foundations for ETL

foundations_dataset = Dataset::Utils.initialize_dataset('foundations', true)
foundation_founders_dataset = Dataset::Utils.initialize_dataset('foundation_founders', true)
foundation_trustees_dataset = Dataset::Utils.initialize_dataset('foundation_trustees', true)
foundation_liquidators_dataset = Dataset::Utils.initialize_dataset('foundation_liquidators', true)

Dataset::Utils.create_relation(foundations_dataset, foundation_founders_dataset)
Dataset::Utils.create_relation(foundation_founders_dataset, foundations_dataset)

Dataset::Utils.create_relation(foundations_dataset, foundation_trustees_dataset)
Dataset::Utils.create_relation(foundation_trustees_dataset, foundations_dataset)

Dataset::Utils.create_relation(foundations_dataset, foundation_liquidators_dataset)
Dataset::Utils.create_relation(foundation_liquidators_dataset, foundations_dataset)


# Lawyers for the ETL

lawyer_dataset = Dataset::Utils.initialize_dataset('lawyers', true)
lawyer_associates_dataset = Dataset::Utils.initialize_dataset('lawyer_partnerships', true)
lawyer_partnership_dataset = Dataset::Utils.initialize_dataset('lawyer_associates', true)

Dataset::Utils.create_relation(lawyer_dataset, lawyer_associates_dataset)
Dataset::Utils.create_relation(lawyer_dataset, lawyer_partnership_dataset)

Dataset::Utils.create_relation(lawyer_associates_dataset, lawyer_dataset)
Dataset::Utils.create_relation(lawyer_associates_dataset, lawyer_dataset, true)
Dataset::Utils.create_relation(lawyer_associates_dataset, lawyer_partnership_dataset)

Dataset::Utils.create_relation(lawyer_partnership_dataset, lawyer_dataset)
Dataset::Utils.create_relation(lawyer_partnership_dataset, lawyer_associates_dataset)


# Notaries for the ETL

notary_dataset = Dataset::Utils.initialize_dataset('notaries', true)
notary_employees_dataset = Dataset::Utils.initialize_dataset('notary_employees', true)

Dataset::Utils.create_relation(notary_dataset, notary_employees_dataset)
Dataset::Utils.create_relation(notary_employees_dataset, notary_dataset)


# Executors for the ETL

Dataset::Utils.initialize_dataset('executors', true)
Dataset::Utils.initialize_dataset('otvorenezmluvy', true)

# MZVSR Contracts
Dataset::Utils.initialize_dataset('mzvsr_contracts', true)

# Data Formats

DataFormat.find_or_create_by_name('flag')
DataFormat.find_or_create_by_name('zip')
DataFormat.find_or_create_by_name('ico')
DataFormat.find_or_create_by_name('history')

[
  {:name => "theme",
   :en_description => "Theme",
   :value => "default"
  },
  {
    :name => "site_name",
    :en_description => "Site Name",
    :value => "Datacamp Site"
  },
  {
    :name => "default_import_format",
    :en_description => "Default import format",
    :value => "csv"
  },
  {
    :name => "login_required",
    :en_description => "Login required to use application",
    :value => 1
  },
  {
    :name => "copyright_notice",
    :en_description => "Copyright notice displayed in the footer.",
    :value => "&copy; Your Comapny"
  },
  {
    :name => "private_mode",
    :en_description => "Users can't register, only subscribe for beta program.",
    :value => 1
  },
  {
    :name => "registration_confirmation_required",
    :en_description => "Users need their accounts confirmed by admin before being able to use them.",
    :value => 0
  },
  {
    :name => "meta_information",
    :en_description => "Meta information that is inserted in the head portion of the webpage",
    :value => nil
  }
].each do |system_variable_attrs|
  SystemVariable.find_or_create_by_name(system_variable_attrs[:name], system_variable_attrs.except(:name))
end
