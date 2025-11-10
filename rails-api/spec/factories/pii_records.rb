# frozen_string_literal: true

FactoryBot.define do
  factory :pii_record do
    user {nil}
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    middle_name { Faker::Name.middle_name }
    middle_name_override { false }
    ssn { '234-56-7890' }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 100) }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    street_address_1 { Faker::Address.street_address }
    street_address_2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip_code { Faker::Address.zip_code }
    deleted_at { nil }

    # Trait for soft-deleted records
    trait :deleted do
      deleted_at { 1.day.ago }
    end

    # Trait for records with no middle name
    trait :no_middle_name do
      middle_name { nil }
    end

    # Trait for records with middle_name_override set
    trait :middle_name_na do
      middle_name_override { true }
    end

    # Trait for minimal valid record
    trait :minimal do
      middle_name { nil }
      date_of_birth { nil }
      email { nil }
      phone { nil }
      street_address_2 { nil }
    end
  end
end
