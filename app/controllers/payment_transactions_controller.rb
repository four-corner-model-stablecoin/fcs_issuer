# frozen_string_literal: true

class PaymentTransactionsController < ApplicationController
  def index
    @payment_transactions = PaymentTransaction.all.order(transaction_time: :DESC)
  end
end
