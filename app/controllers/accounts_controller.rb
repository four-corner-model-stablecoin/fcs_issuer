# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :signed_in?, only: %i[show new create]

  def new
    @account_transactions = current_user.account.account_transaction.order(transaction_time: :DESC)
  end


  def create
    amount = deposit_params['amount'].to_i
    account = current_user.account
    account.update!(balance: account.balance + amount)

    AccountTransaction.create(
      account:,
      amount:,
      transaction_type: 0,
      transaction_time: Time.current
    )
    redirect_to user_path
  end

  private

  def deposit_params
    params.require(:account).permit(:amount)
  end
end
