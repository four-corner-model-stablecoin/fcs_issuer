# frozen_string_literal: true

class PaymentRequest < ApplicationRecord
  validates :request_id, presence: true

  belongs_to :user
  belongs_to :stable_coin

  enum status: {
    created: 0,
    completed: 1,
    transfering: 2,
    failed: 9
  }
end
