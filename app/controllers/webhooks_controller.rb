# Controller to handle all received webhooks
class WebhooksController < ApplicationController

  # error class to handle unsupported event types
  class UnsupportedEventTypeError < StandardError; end

  SUPPORTED_EVENTS = %w[
    customer.created
    customer.updated
    customer.subscription.created
    invoice.payment_succeeded
    customer.subscription.deleted
  ].freeze

  KNOWN_ERRORS = [
    ActiveRecord::RecordInvalid,
    JSON::ParserError,
    UnsupportedEventTypeError
  ].freeze

  # method to handle all received webhooks
  def receive
    stripe_event = handle_event(request)
    upsert_user(stripe_event) if ['customer.created', 'customer.updated'].include?(stripe_event.type)
    create_subscription(stripe_event) if stripe_event.type == 'customer.subscription.created'
    pay_subscription(stripe_event) if stripe_event.type == 'invoice.payment_succeeded'
    cancel_subscription(stripe_event) if stripe_event.type == 'customer.subscription.deleted'
  rescue *KNOWN_ERRORS => e
    render json: { error: e.message }, status: :bad_request
  end


  private

  def handle_event(request)
    event = Stripe::Event.construct_from(
      JSON.parse(request.body.read), symbolize_names: true
    )

    raise UnsupportedEventTypeError, "Unsupported event type: #{event.type}" if SUPPORTED_EVENTS.exclude?(event.type)

    event
  end

  def upsert_user(event)
    user = User.find_or_initialize_by(external_id: event.data.object.id)
    user.update!(
      name: event.data.object.name,
      email: event.data.object.email
    )
  end

  def create_subscription(event)
    return unless event.data.object.status == 'active'

    Subscription.new(
      external_id: event.data.object.id,
      user: User.find_by(external_id: event.data.object.customer)
    ).save
  end

  def pay_subscription(event)
    return unless event.data.object.status == 'paid'

    subscription = Subscription.find_by(external_id: event.data.object.subscription)
    subscription.update!(status: :paid)
  end

  def cancel_subscription(event)
    return unless event.data.object.status == 'canceled'

    subscription = Subscription.find_by(external_id: event.data.object.id)
    subscription.update!(status: :canceled) if subscription.paid?
  end
end
