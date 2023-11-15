# frozen_string_literal: true

# ブランド - イシュア間の契約を管理するモデル
# 1契約で1ステーブルコインを発行する
# 契約モデルないでカラー識別子および導出元スクリプトを管理
class Contract < ApplicationRecord
  has_one :stable_coin

  belongs_to :brand_did, class_name: 'Did', foreign_key: 'brand_did_id'
  belongs_to :issuer_did, class_name: 'Did', foreign_key: 'issuer_did_id'

  validates :script_pubkey, presence: true
  validates :redeem_script, presence: true
  validates :contracted_at, presence: true
  validates :effect_at, presence: true
  validates :expire_at, presence: true
end
