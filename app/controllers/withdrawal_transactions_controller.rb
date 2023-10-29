# frozen_string_literal: true

class WithdrawalTransactionsController < ApplicationController
  def index
    @withdrawal_transactions = WithdrawalTransaction.all.order(transaction_time: :DESC)
  end
end
