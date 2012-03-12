FactoryGirl.define do
  
  factory :field_description do
    is_visible_in_listing true
    is_visible_in_detail true
    sk_category 'sk other'
    en_category 'en other'
    sk_title 'sk title'
    en_title 'sk title'
  end
  
  factory :dataset_category, :aliases => [:category] do
    sk_title 'sk title'
    en_title 'sk title'
  end
  
  factory :dataset_description do
    identifier 'something'
    sk_title 'sk title'
    en_title 'sk title'
    is_active true
    category
  end
  
end