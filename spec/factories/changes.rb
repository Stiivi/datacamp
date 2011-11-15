FactoryGirl.define do
  
  factory :change do
    association :dataset_description
    record_id 1
    changed_field 'cool_field'
    value 'new_field_value'
  end
  
end