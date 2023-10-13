# frozen_string_literal: true

# サービス内で流通するトークンを管理するモデル
class StableCoin < ApplicationRecord
  validates :color_id, presence: true

  TOKEN_ID = 1 # TODO: .envにでも書きたい

  # def self.instance
  #   find_or_create_by!(id: TOKEN_ID)
  # end

  # 発行済みトークンの総量
  def total_amount
    tx_outset_info = Glueby::Internal::RPC.client.gettxoutsetinfo
    tx_outset_info['total_amount'][glueby_token.color_id.to_payload.bth]
  end
end
