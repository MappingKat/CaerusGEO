# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report do
    title "test Report"
    status false
    survey nil
    user nil
  end
end
