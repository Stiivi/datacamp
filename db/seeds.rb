# -*- encoding : utf-8 -*-
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

EtlConfiguration.find_or_create_by_name('vvo_extraction', :start_id => 2642, :batch_limit => 1000)
EtlConfiguration.find_or_create_by_name('notary_extraction', :start_id => 1, :batch_limit => 100)
EtlConfiguration.find_or_create_by_name('executor_extraction')
EtlConfiguration.find_or_create_by_name('lawyer_extraction')
EtlConfiguration.find_or_create_by_name('donations_parser', parser: true)
EtlConfiguration.find_or_create_by_name('otvorenezmluvy_extraction', start_id: 201110)
EtlConfiguration.find_or_create_by_name('foundation_extraction')

def initialize_dataset(name)
  if Dataset::DatasetRecord.connection.table_exists?("ds_#{name}")
    puts "initializing #{name}"
    dataset_base = Dataset::Base.new(name)
    dataset_base.add_primary_key
    dataset_base.add_system_columns
    puts 'finished transormation'
    puts dataset_base.errors
    dataset_base.create_description!
    puts 'finished creating dataset description'
    puts '--------'
  end
end

# Foundations for ETL
initialize_dataset('foundations')
initialize_dataset('foundation_founders')
initialize_dataset('foundation_trustees')
initialize_dataset('foundation_liquidators')

foundations_description = DatasetDescription.find_by_identifier!('foundations')
foundation_founders_description = DatasetDescription.find_by_identifier!('foundation_founders')
foundation_trustees_description = DatasetDescription.find_by_identifier!('foundation_trustees')
foundation_liquidators_description = DatasetDescription.find_by_identifier!('foundation_liquidators')

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundations_description.id, foundation_founders_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundation_founders_description.id, foundations_description.id)

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundations_description.id, foundation_trustees_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundation_trustees_description.id, foundations_description.id)

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundations_description.id, foundation_liquidators_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(foundation_liquidators_description.id, foundations_description.id)

# Lawyers for the ETL
initialize_dataset('lawyers')
initialize_dataset('lawyer_partnerships')
initialize_dataset('lawyer_associates')

lawyer_description = DatasetDescription.find_by_identifier!('lawyers')
lawyer_associates_description = DatasetDescription.find_by_identifier!('lawyer_associates')
lawyer_partnership_description = DatasetDescription.find_by_identifier!('lawyer_partnerships')

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_description.id, lawyer_associates_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_description.id, lawyer_partnership_description.id)

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_associates_description.id, lawyer_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id_and_morph(lawyer_associates_description.id, lawyer_description.id, true)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_associates_description.id, lawyer_partnership_description.id)

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_partnership_description.id, lawyer_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_partnership_description.id, lawyer_associates_description.id)

# Notaries for the ETL
initialize_dataset('notaries')
initialize_dataset('notary_employees')

notary_description = DatasetDescription.find_by_identifier!('notaries')
notary_employees_description = DatasetDescription.find_by_identifier!('notary_employees')

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(notary_description.id, notary_employees_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(notary_employees_description.id, notary_description.id)

# Executors for the ETL
initialize_dataset('executors')


initialize_dataset('otvorenezmluvy')


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
