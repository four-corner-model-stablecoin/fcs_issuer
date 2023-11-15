# frozen_string_literal: true

# ステーブルコイン発行リクエストモデル
class IssuanceRequest < ApplicationRecord
  validates :request_id, presence: true

  belongs_to :issuance_transaction, optional: true
  belongs_to :stable_coin
  belongs_to :user

  enum status: {
    created: 0, # 作成済み
    completed: 1, # 完了
    failed: 9 # 失敗
  }
end
