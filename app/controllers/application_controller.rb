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
    @current_user ||= (User.find_by(id: session[:user_id]) if session[:user_id]) || User.first
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

  def resolve_did(did)
    response = Net::HTTP.get(URI("#{ENV['DID_SERVICE_URL']}/did/resolve/#{did.short_form}"))
    public_key_jwk = JSON.parse(response)['did']['didDocument']['verificationMethod'][0]['publicKeyJwk']
    jwk = JSON::JWK.new(public_key_jwk)

    jwk_to_tapyrus_key(jwk)
  end

  def jwk_to_tapyrus_key(jwk)
    key = jwk.to_key

    if key.private_key.nil?
      Tapyrus::Key.new(pubkey: key.public_key.to_bn.to_s(16).downcase.encode('US-ASCII'), key_type: 0)
    else
      Tapyrus::Key.new(priv_key: key.private_key.to_s(16).downcase.encode('US-ASCII'), key_type: 0)
    end
  end
end
