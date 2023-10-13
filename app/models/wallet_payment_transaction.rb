# frozen_string_literal: true

class WalletPaymentTransaction < ApplicationRecord
  belongs_to :wallet

  enum payment_type: {
    charge: 0,
    payment: 1,
    withdrew: 2
  }

  validates :amount, presence: true
  validates :payment_type, presence: true
  validates :transaction_time, presence: true
end
