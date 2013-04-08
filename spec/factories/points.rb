# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :point do
    lat 1.5
    lng 1.5
    location_id 1
    location_type "MyString"
  end
end
