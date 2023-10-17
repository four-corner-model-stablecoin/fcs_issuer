# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :signed_in?, only: %i[show]

  def show
    @user = current_user
  end

  def new; end

  def create
    user = User.create(username: user_params['username'])
    user.build_account.save!
    user.build_wallet.save!
    # User作成の前に、Userから提示されたDIDが正しいのかなどの処理は必要そう。
    Did.create!(user:, short_form: user_params['did'])

    sign_in(user)

    redirect_to user_path
  end

  private

  def user_params
    params.require(:user).permit(:username, :did)
  end
end
