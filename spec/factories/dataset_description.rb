FactoryGirl.define do

  factory :field_description_category do
    sk_title 'sk title'
    en_title 'en title'
  end

  factory :field_description do
    is_visible_in_listing true
    is_visible_in_detail true
    sk_category 'sk other'
    en_category 'en other'
    sk_title 'sk title'
    en_title 'en title'
    data_type 'string'
  end

  factory :dataset_category, :aliases => [:category] do
    sk_title 'sk title'
    en_title 'en title'
  end

  factory :dataset_description do
    ignore do
      with_dataset false
    end

    sk_title 'sk title'
    en_title 'en title'
    # FIXME: need to pass en_title when using factory, just title will not be used for identifier
    identifier { |dataset| dataset.title.to_s.parameterize.underscore  }
    is_active true
    category

    after(:create) do |dataset_description, evaluator|
      dataset_description.dataset.setup_table if evaluator.with_dataset
    end
  end

end
