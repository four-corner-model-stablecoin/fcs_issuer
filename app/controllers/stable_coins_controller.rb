# frozen_string_literal: true

class StableCoinsController < ApplicationController
  before_action :signed_in?

  def new
    @wallet_transactions = current_user.wallet.wallet_transaction.order(transaction_time: :DESC)
  end

  def create
    amount = deposit_params[:amount].to_i
    stable_coin = StableCoin.last
    script_pubkey = Tapyrus::Script.parse_from_payload(stable_coin.contract.script_pubkey.htb)
    redeem_script = Tapyrus::Script.parse_from_payload(stable_coin.contract.redeem_script.htb)

    # 大元のUTXOを作成する
    txid = Glueby::Internal::RPC.client.sendtoaddress(script_pubkey.to_addr, 1)
    generate_block
    input_tx = Tapyrus::Tx.parse_from_payload(Glueby::Internal::RPC.client.getrawtransaction(txid).htb)

    # unsigned_tx作成する
    tx = Tapyrus::Tx.new
    vout = 0
    input_tx.outputs.each_with_index do |output, i|
      vout = i if output.script_pubkey == script_pubkey
    end
    input_tapyrus = input_tx.outputs[vout].value
    tx.in << Tapyrus::TxIn.new(out_point: Tapyrus::OutPoint.from_txid(txid, vout))

    fee = 0.00003
    fee_tapyrus = (fee * (10**8)).to_i
    change_tapyrus = input_tapyrus - fee_tapyrus

    # colorの導出
    user_key = resolve_did(current_user.did)
    issuer_key =Tapyrus::Key.new(priv_key: stable_coin.contract.issuer_did.key.private_key, key_type: 0)
    brand_key = resolve_did(stable_coin.contract.brand_did)
    two_of_three_color_script= Tapyrus::Script.new << stable_coin.color_id << Tapyrus::Opcodes::OP_COLOR << Tapyrus::Opcodes::OP_2 << user_key.pubkey << issuer_key.pubkey << brand_key.pubkey << Tapyrus::Opcodes::OP_3 << Tapyrus::Opcodes::OP_CHECKMULTISIG 

    # ステーブルコインを 2of3 マルチシグでロックする
    tx.out << Tapyrus::TxOut.new(value: amount, script_pubkey: two_of_three_color_script)
    tx.out << Tapyrus::TxOut.new(value: change_tapyrus, script_pubkey: Tapyrus::Script.parse_from_addr(Glueby::Internal::RPC.client.getnewaddress))

    # txにsignする
    params_json = {
      color_id: stable_coin.color_id,
      unsigned_tx: tx.to_hex
    }.to_json
    response = Net::HTTP.post(
      URI('http://localhost:3001/stable_coins/issue'),
      params_json,
      'Content-Type' => 'application/json'
    )

    sig_hash = tx.sighash_for_input(0, redeem_script)
    sig1 = JSON.parse(response.body)['signature'].htb
    sig2 = issuer_key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
    script_sig = Tapyrus::Script.new << OP_0 << sig2 << sig1 << redeem_script.to_payload

    tx.in[0].script_sig = script_sig

    Glueby::Internal::RPC.client.sendrawtransaction(tx.to_payload.bth)

    account = current_user.account
    account.update!(balance: account.balance - amount)

    wallet = current_user.wallet
    wallet.update!(balance: wallet.balance + amount)

    CoinTransaction.create(
      stable_coin:,
      wallet:,
      tx_hex: tx.to_hex, 
      amount: tx.outputs[vout].value,
      payment_type: 0,
      transaction_time: Time.current
    )

    WalletTransaction.create(
      wallet:,
      amount: tx.outputs[vout].value,
      payment_type: 0,
      transaction_time: Time.current
    )

    AccountTransaction.create(
      account: account,
      amount: -tx.outputs[vout].value,
      payment_type: 1,
      transaction_time: Time.current
    )
    generate_block
    redirect_to user_path, notice: "Issue successful."
  end

  private

  def deposit_params
    params.require(:stable_coin).permit(:amount)
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
    response = Net::HTTP.get(URI("#{ENV['DID_SERVICE_URI']}/did/resolve/#{did.short_form}"))
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
