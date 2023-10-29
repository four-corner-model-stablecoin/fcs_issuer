# frozen_string_literal: true

class WalletsController < ApplicationController
  before_action :signed_in?, only: %i[show new create]
  before_action :has_wallet?, only: %i[show]
  before_action :already_has_wallet, only: %i[new create]

  def show
    @wallet = current_user.wallet
    @wallet_transactions = @wallet.wallet_transactions.order(transaction_time: :DESC)
  end

  def new; end

  def create
    current_user.build_wallet.save!
    redirect_to wallet_path
  end

  private

  def has_wallet?
    redirect_to new_wallet_path unless current_user.wallet
  end

  def already_has_wallet
    redirect_to wallet_path if current_user.wallet
  end
end
