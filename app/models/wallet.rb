# frozen_string_literal: true

# 顧客ウォレットモデル
# カストディ型なのでDB上で非同期的に残高を反映させるのみ
# この直を用いてオーソリ可否を判断する
class Wallet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :wallet_transactions
  has_many :stable_coin_transactions
end
