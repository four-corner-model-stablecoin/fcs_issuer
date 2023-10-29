# frozen_string_literal: true

class WalletTransaction < ApplicationRecord
  validates :amount, presence: true
  validates :transaction_type, presence: true
  validates :transaction_time, presence: true

  has_one :issuance_transaction
  has_one :payment_transaction
  belongs_to :wallet

  enum transaction_type: {
    deposit: 0, # 入金
    withdrawal: 1, # 出金
    transfer: 2 # 送金
  }
end
