# frozen_string_literal: true

class AccountTransaction < ApplicationRecord
  belongs_to :account

  enum payment_type: {
    deposit: 0,
    withdrawal: 1
  }

  validates :amount, presence: true
  validates :payment_type, presence: true
  validates :transaction_time, presence: true
end
