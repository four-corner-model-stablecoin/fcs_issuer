# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :wallet_payment_transaction

  # カラムでbalanceを都度アップデートしていくならいらない？
  # def balance
  #   StableCoin.instance.glueby_token.amount(wallet: glueby_wallet)
  # end
end
