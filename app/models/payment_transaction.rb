# frozen_string_literal: true

# ステーブルコイン送金履歴モデル
class PaymentTransaction < ApplicationRecord
  validates :amount, presence: true
  validates :txid, presence: true
  validates :vc, presence: true
  validates :transaction_time, presence: true

  has_one :payment_request
  belongs_to :wallet_transaction
end
