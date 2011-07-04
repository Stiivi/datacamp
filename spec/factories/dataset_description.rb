FactoryGirl.define do
  
  factory :field_description do
    is_visible_in_listing true
    is_visible_in_detail true
    category 'other'
    title 'test'
  end
  
  factory :dataset_category, :aliases => [:category] do
    title 'test category'
  end
  
  factory :dataset_description do
    identifier 'something'
    title 'somethinsomething'
    is_active true
    category
  end
  
end