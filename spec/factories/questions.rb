# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :question do
    index 1
    label "MyString"
    form "MyString"
    note "MyString"
    survey Survey.new
  end
end
