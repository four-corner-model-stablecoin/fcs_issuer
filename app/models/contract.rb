# frozen_string_literal: true

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
