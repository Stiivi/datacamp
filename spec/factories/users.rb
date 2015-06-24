FactoryGirl.define do
  
  factory :user do
    sequence(:login) { |n| "test_#{n}" }
    name { |user| user.login }
    email { |user| "#{user.login.to_s.parameterize}@mail.com" }
    accepts_terms '1'
    password 'password'
    password_confirmation { |user| user.password }
    is_super_user true
  end
  
end