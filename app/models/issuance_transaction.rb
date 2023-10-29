# frozen_string_literal: true

class IssuanceTransaction < ApplicationRecord
  validates :amount, presence: true
  validates :txid, presence: true
  validates :transaction_time, presence: true

  has_one :issuance_request
  belongs_to :stable_coin_transaction
  belongs_to :wallet_transaction
  belongs_to :account_transaction
end
