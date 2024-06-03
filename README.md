### Billing Subscrition

A repository to experiment with Stripe webhooks.

1. What do you need

- Ruby on Rails
- Stripe CLI

1. Run the application

```
bin/rails s -p 3001
```

2. Redirect events to the local server

```
stripe listen --forward-to localhost:3001/stripe_webhooks
```

3. Interact with Stripe and do the following actions

- Create a subscription for a customer.
- If the customer does not exists yet, remember to create it and to add an email, otherwise, the subscription can't be created.
- The customer must have a payment method. A Stripe fake credit card can be used as explained [here](https://docs.stripe.com/testing) 
2.  Pay the subscription from **Invoices >> Charge customer**
3. Cancel the subscription only if it is paid.

4. You can corroborate each previous action in the Rails Console if needed

- Check for the user and its subscriptions 

```
user = User.last
user.subscriptions
```

ℹ️ _The external_id of user and subscription models, corresponds to the id in Stripe_

- Check for the status of the subscription once created

```
subscription = Subscription.find_by(external_id: stripe_subscripion_id) 
subscription.unpaid?
```

- Check for the status of the subscription once paid

```
subscription = Subscription.find_by(external_id: stripe_subscripion_id) 
subscription.paid?
```

- Check for the status of the subscription once canceled

```
subscription = Subscription.find_by(external_id: stripe_subscripion_id) 
subscription.canceled?
```
