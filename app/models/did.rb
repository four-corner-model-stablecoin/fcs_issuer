# frozen_string_literal: true

# DIDを管理するモデル
class Did < ApplicationRecord
  validates :short_form, presence: true

  has_one :key
  has_one :user
  has_many :contract_as_brand, class_name: 'Contract', foreign_key: 'brand_did_id'
  has_many :contract_as_issuer, class_name: 'Contract', foreign_key: 'issuer_did_id'
end
