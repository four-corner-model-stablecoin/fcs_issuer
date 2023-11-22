# frozen_string_literal: true

module Api
  class PaymentRequestsController < ApplicationController
    def show
      request = PaymentRequest.find_by(request_id: params[:id])
      transaction = request&.payment_transaction
      user = request&.user
      stable_coin = request&.stable_coin

      render json: { request:, transaction:, user:, stable_coin: }
    end
  end
end

