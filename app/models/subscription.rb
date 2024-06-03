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
end
