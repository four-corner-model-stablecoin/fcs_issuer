# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :wallet_transaction
  has_many :stable_coin_transactions

  # カラムでbalanceを都度アップデートしていくならいらない？
  # def balance
  #   StableCoin.instance.glueby_token.amount(wallet: glueby_wallet)
  # end
end
