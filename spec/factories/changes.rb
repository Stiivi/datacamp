FactoryGirl.define do
  
  factory :change do
    change_type Change::RECORD_UPDATE
    association :dataset_description
    record_id 1
    change_details [{changed_field: 'cool_field', old_value: 'old_field_value', new_value: 'new_field_value'}]
  end
  
end