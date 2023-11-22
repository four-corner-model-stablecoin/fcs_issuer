# frozen_string_literal: true

module Api
  class IssuanceRequestsController < ApplicationController
    def show
      request = IssuanceRequest.find_by(request_id: params[:id])
      transaction = request&.issuance_transaction
      user = request&.user
      stable_coin = request&.stable_coin

      render json: { request:, transaction:, user:, stable_coin: }
    end
  end
end
