# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :survey do
    title "MyString"
    description "MyString"
    status true
    time_zone "Pacific Time (US & Canada)"
  end
end
