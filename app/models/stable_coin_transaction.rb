# frozen_string_literal: true

# ステーブルコイン増減履歴モデル（発行償還履歴）
class StableCoinTransaction < ApplicationRecord
  validates :amount, presence: true
  validates :transaction_type, presence: true
  validates :transaction_time, presence: true

  has_one :issuance_transaction
  has_one :withdrawal_transaction
  belongs_to :stable_coin

  enum transaction_type: {
    issue: 0,
    burn: 1
  }
end
