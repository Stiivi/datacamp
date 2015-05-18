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
    sk_title 'sk title'
    en_title 'sk title'
    identifier { |dataset| dataset.sk_title.to_s.underscore }
    is_active true
    category
  end

end
