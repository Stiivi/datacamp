FactoryGirl.define do

  factory :field_description do
    is_visible_in_listing true
    is_visible_in_detail true
    sk_category 'sk other'
    en_category 'en other'
    sk_title 'sk title'
    en_title 'en title'
  end

  factory :dataset_category, :aliases => [:category] do
    sk_title 'sk title'
    en_title 'en title'
  end

  factory :dataset_description do
    sk_title 'sk title'
    en_title 'en title'
    # need to pass en_title, just title will not work, don't know why
    identifier { |dataset| dataset.title.to_s.parameterize.underscore  }
    is_active true
    category
  end

end
