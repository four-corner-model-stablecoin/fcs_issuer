# frozen_string_literal: true

class WalletPaymentTransaction < ApplicationRecord
  belongs_to :wallet

  validates :payee, presence: true
  validates :payer, presence: true
  validates :amount, presence: true
  validates :transaction_time, presence: true
end
