# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :redirect_if_no_contracts, only: [:index]

  def index; end

  def redirect_if_no_contracts
    redirect_to new_contract_path if Contract.count.zero?
  end
end
