require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  should belong_to(:user)
  should define_enum_for(:status).with_values(%i[unpaid paid canceled])

  test 'update subscription status to paid only if subscription is unpaid' do
    subscription = create(:subscription)

    subscription.status = :paid

    assert subscription.paid?
  end

  test 'update subscription status to canceled only if subscription is paid' do
    subscription = create(:subscription, :paid)

    subscription.status = :canceled

    assert subscription.canceled?
  end

  test 'return error if subscription is being canceled but is unpaid' do
    subscription = create(:subscription)

    subscription.status = :canceled

    assert_not subscription.valid?
    assert_includes subscription.errors.full_messages.join(''), "Can't cancel if subscription is unpaid"
  end

  test 'return error is subscription is being canceled and is already canceled' do
    subscription = create(:subscription, :canceled)

    subscription.status = :canceled

    assert_not subscription.valid?
    assert_includes subscription.errors.full_messages.join(''), "Can't cancel if subscription is canceled"
  end

  test 'return error if subscription is being paid but is already paid' do
    subscription = create(:subscription, :paid)

    subscription.status = :paid

    assert_not subscription.valid?
    assert_includes subscription.errors.full_messages.join(''), "Can't pay if subscription is paid"
  end

  test 'return error if subscription is being paid but is canceled' do
    subscription = create(:subscription, :canceled)

    subscription.status = :paid

    assert_not subscription.valid?
    assert_includes subscription.errors.full_messages.join(''), "Can't pay if subscription is canceled"
  end
end
