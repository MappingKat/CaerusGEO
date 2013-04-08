# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :area do
    city "MyString"
    country "MyString"
    thumbnail "MyString"
    survey nil
  end
end
