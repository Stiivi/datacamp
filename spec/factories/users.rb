FactoryGirl.define do
  
  factory :user do
    login 'test'
    name 'testing tester'
    email 'test@example.com'
    accepts_terms '1'
    password 'password'
    password_confirmation 'password'
    is_super_user true
  end
  
end