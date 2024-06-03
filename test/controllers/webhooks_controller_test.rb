require 'test_helper'
require 'json'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  test 'create new user locally if event is customer.created' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_customer_creation_success.json'))
    event_json = JSON.parse(event)

    post stripe_webhooks_url, params: event

    expected_external_id = event_json['data']['object']['id']
    expected_email = event_json['data']['object']['email']
    expected_name = event_json['data']['object']['name']

    new_user = User.find_by(external_id: expected_external_id)

    assert_response :success
    assert_equal expected_external_id, new_user.external_id
    assert_equal expected_email, new_user.email
    assert_equal expected_name, new_user.name
  end

  test 'update user if event is customer.created' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_customer_updated_success.json'))
    event_json = JSON.parse(event)
    user = create(:user, external_id: 'customer_id', name: 'old name', email: 'old_email@email.com')
    expected_email = event_json['data']['object']['email']
    expected_name = event_json['data']['object']['name']

    post stripe_webhooks_url, params: event

    user.reload

    assert_response :success
    assert_equal expected_email, user.email
    assert_equal expected_name, user.name
  end

  test 'create new subscription locally if event is customer.subscription.created' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_subscription_creation_success.json'))
    event_json = JSON.parse(event)
    expected_external_id = event_json['data']['object']['id']
    create(:user, external_id: event_json['data']['object']['customer'])

    post stripe_webhooks_url, params: event

    new_subscription = Subscription.find_by(external_id: expected_external_id)

    assert_response :success
    assert_equal expected_external_id, new_subscription.external_id
    assert new_subscription.unpaid?
  end

  test 'update subscription status to paid if event is invoice.payment_succeeded' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_payment_succeeded.json'))
    user = create(:user, external_id: 'customer_id')
    subscription = create(:subscription, external_id: 'subscription_id', user: user)

    post stripe_webhooks_url, params: event

    subscription.reload
    assert subscription.paid?
  end

  test 'update subscription status to cancelled if event is customer.subscription.deleted and subscription is paid' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_customer_subscription_canceled.json'))
    user = create(:user, external_id: 'customer_id')
    subscription = create(:subscription, external_id: 'subscription_id', user: user, status: :paid)

    post stripe_webhooks_url, params: event

    subscription.reload

    assert subscription.canceled?
    assert_not subscription.paid?
    assert_not subscription.unpaid?
  end

  test 'not update subscription status if event is customer.subscription.deleted and subscription is unpaid' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_customer_subscription_canceled.json'))
    user = create(:user, external_id: 'customer_id')
    subscription = create(:subscription, external_id: 'subscription_id', user: user)

    post stripe_webhooks_url, params: event

    subscription.reload

    assert_not subscription.canceled?
    assert_not subscription.paid?
    assert subscription.unpaid?
  end

  test 'return UnsupportedEventTypeError if event received is not supported' do
    event = { 'type' => 'climate.product.pricing_updated' }
    event = event.to_json
    controller = WebhooksController.new
    WebhooksController.stubs(:new).returns(controller)
    controller.stubs(:handle_event).raises(WebhooksController::UnsupportedEventTypeError, 'Unsupported event type: climate.product.pricing_updated')

    post stripe_webhooks_url, params: event

    assert_equal 'Unsupported event type: climate.product.pricing_updated', JSON.parse(response.body)['error']
  end

  test 'return bad request if updating database returns ActiveRecord::RecordInvalid' do
    event = File.read(Rails.root.join('test', 'fixtures', 'files', 'event_payment_succeeded.json'))
    user = create(:user, external_id: 'customer_id')
    subscription = create(:subscription, :paid, external_id: 'subscription_id', user: user)

    controller = WebhooksController.new
    WebhooksController.stubs(:new).returns(controller)
    controller.stubs(:pay_subscription).raises(ActiveRecord::RecordInvalid.new(subscription))

    post stripe_webhooks_url, params: event

    assert_response :bad_request
    assert_includes JSON.parse(response.body)['error'], 'Validation failed'
  end

  test 'return bad request if updating database returns JSON::ParserError' do
    event = { 'type' => 'customer.created' }
    event = event.to_json

    controller = WebhooksController.new
    WebhooksController.stubs(:new).returns(controller)
    controller.stubs(:handle_event).raises(JSON::ParserError)

    post stripe_webhooks_url, params: event

    assert_response :bad_request
    assert_includes JSON.parse(response.body)['error'], 'JSON::ParserError'
  end
end
