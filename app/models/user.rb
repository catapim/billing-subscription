# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  external_id :string           not null
#  name        :string
#  email       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_users_on_external_id  (external_id) UNIQUE
#
class User < ApplicationRecord
end
