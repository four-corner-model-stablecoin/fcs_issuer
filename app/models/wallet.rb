# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :wallet_transactions
  has_many :stable_coin_transactions
end
