class ApplicationController < ActionController::Base
  helper_method :current_user, :signed_in?, :generate_block
  protect_from_forgery

  private

  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    return if current_user

    redirect_to login_path
  end

  def generate_block
    address =  Glueby::Internal::RPC.client.getnewaddress
    aggregate_private_key = ENV['TAPYRUS_AUTHORITY_KEY']
    Glueby::Internal::RPC.client.generatetoaddress(1, address, aggregate_private_key)

    latest_block_num = Glueby::Internal::RPC.client.getblockcount
    synced_block = Glueby::AR::SystemInformation.synced_block_height
    (synced_block.int_value + 1..latest_block_num).each do |height|
      Glueby::BlockSyncer.new(height).run
      synced_block.update(info_value: height.to_s)
    end
  end
end
