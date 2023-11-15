# frozen_string_literal: true

# ステーブルコイン送金リクエストモデル
class PaymentRequest < ApplicationRecord
  validates :request_id, presence: true
  validates :vc, presence: true

  belongs_to :payment_transaction, optional: true
  belongs_to :stable_coin
  belongs_to :user

  enum status: {
    created: 0,
    completed: 1,
    transfering: 2,
    failed: 9
  }
end
