FactoryGirl.define do
  factory :etl_configuration do
    name 'executor_extraction'

    factory :donations_parser do
      name 'donations_parser'
      parser true
    end
  end
end
