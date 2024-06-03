FactoryBot.define do
  factory :user do
    name { 'name' }
    sequence :email do |n|
      "user_#{n}@host.com"
    end
    external_id { SecureRandom.hex(10) }
  end

  factory :subscription do
    user
    external_id { SecureRandom.hex(10) }
    status { 0 }

    trait :paid do
      after(:create) do |subscription|
        subscription.status = :paid
        subscription.save
      end
    end

    # trait for a canceled subscription. it is needed because by default these are created as unpaid
    # and we have model validations that prevent a subscription from being canceled if it is unpaid
    trait :canceled do
      after(:create) do |subscription|
        subscription.update!(status: :paid)
        subscription.status = :canceled
        subscription.save
      end
    end
  end
end