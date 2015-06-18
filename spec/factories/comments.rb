FactoryGirl.define do

  factory :comment do
    title 'title'
    text 'text'
    association :user
  end
end