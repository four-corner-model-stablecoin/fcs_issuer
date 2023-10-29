# frozen_string_literal: true

class IssuanceTransactionsController < ApplicationController
  def index
    @issuance_transactions = IssuanceTransaction.all.order(transaction_time: :DESC)
  end
end
