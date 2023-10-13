# frozen_string_literal: true

class CoinPaymentTransaction < ApplicationRecord
  belongs_to :stable_coin

  # burnというか償還
  enum payment_type: {
    issue: 0,
    transfer: 1,
    burn: 2
  }

  validates :amount, presence: true
  validates :payment_type, presence: true
  validates :transaction_time, presence: true
end
