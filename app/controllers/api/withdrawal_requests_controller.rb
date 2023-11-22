# frozen_string_literal: true

module Api
  class WithdrawalRequestsController < ApplicationController
    def show
      request = WithdrawalRequest.find_by(request_id: params[:id])
      transaction = request&.withdrawal_transaction
      stable_coin = request&.stable_coin

      render json: { request:, transaction:, stable_coin: }
    end
  end
end
