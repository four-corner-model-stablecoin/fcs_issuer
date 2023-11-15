# frozen_string_literal: true
#
# ステーブルコイン償還履歴モデル
class WithdrawalTransaction < ApplicationRecord
  validates :amount, presence: true
  validates :merchant_to_brand_txid, presence: true
  validates :brand_to_issuer_txid, presence: true
  validates :burn_txid, presence: true
  validates :transaction_time, presence: true

  has_one :withdrawal_request
  belongs_to :stable_coin_transaction
end
