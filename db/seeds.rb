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

# Lawyers for the ETL
initialize_dataset('lawyers')
initialize_dataset('lawyer_partnerships')
initialize_dataset('lawyer_associates')

lawyer_description = DatasetDescription.find_by_identifier!('lawyers')
lawyer_associates_description = DatasetDescription.find_by_identifier!('lawyer_associates')
lawyer_partnership_description = DatasetDescription.find_by_identifier!('lawyer_partnerships')

Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_description.id, lawyer_associates_description.id)
Relation.find_or_create_by_dataset_description_id_and_relationship_dataset_description_id(lawyer_description.id, lawyer_partnership_description)

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


