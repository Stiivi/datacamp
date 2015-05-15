FactoryGirl.define do

  factory :page do
    sequence(:page_name) { |n| "page_name_#{n}" }
    title { |page| page.page_name.to_s.titleize }
    body 'body'
  end
end