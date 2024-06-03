# == Schema Information
#
# Table name: subscriptions
#
#  id          :integer          not null, primary key
#  external_id :string           not null
#  status      :integer          default("unpaid"), not null
#  user_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_subscriptions_on_user_id  (user_id)
#
class Subscription < ApplicationRecord
  belongs_to :user

  enum status: { unpaid: 0, paid: 1, canceled: 2 }

  validate :status_transition, if: -> { status_changed? || status_was == status }

  private

  def status_transition
    case [status_was, status]
    when %w[unpaid canceled]
      errors.add(:status, I18n.t('activerecord.errors.models.subscription.attributes.status.cant_cancel_unpaid'))
    when %w[canceled paid]
      errors.add(:status, I18n.t('activerecord.errors.models.subscription.attributes.status.cant_pay_canceled'))
    when %w[paid paid]
      errors.add(:status, I18n.t('activerecord.errors.models.subscription.attributes.status.cant_pay_paid'))
    when %w[canceled canceled]
      errors.add(:status, I18n.t('activerecord.errors.models.subscription.attributes.status.cant_cancel_canceled'))
    end
  end
end
