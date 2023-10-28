# frozen_string_literal: true

# 発行トークンを管理するモデル
class StableCoin < ApplicationRecord
  validates :color_id, presence: true

  has_many :stable_coin_transactions
  belongs_to :contract

  # 発行済みトークンの総量
  def total_amount
    tx_outset_info = Glueby::Internal::RPC.client.gettxoutsetinfo
    tx_outset_info['total_amount'][glueby_token.color_id.to_payload.bth]
  end
end
