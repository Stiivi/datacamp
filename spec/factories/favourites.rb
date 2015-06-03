FactoryGirl.define do
  factory :favorite do
    association :user
    association :dataset_description
    note 'important'
  end
end