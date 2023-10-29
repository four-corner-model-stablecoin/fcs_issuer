# frozen_string_literal: true

class StableCoinsController < ApplicationController
  before_action :signed_in?

  def new
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
    issuer_key = Did.first.key.to_tapyrus_key
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
      URI("#{ENV['BRAND_URL']}/stable_coins/issue"),
      params_json,
      'Content-Type' => 'application/json'
    )

    sig_hash = tx.sighash_for_input(0, redeem_script)
    sig1 = JSON.parse(response.body)['signature'].htb
    sig2 = issuer_key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
    script_sig = Tapyrus::Script.new << OP_0 << sig2 << sig1 << redeem_script.to_payload

    tx.in[0].script_sig = script_sig

    txid = Glueby::Internal::RPC.client.sendrawtransaction(tx.to_payload.bth)

    request_id = SecureRandom.uuid
    request = IssuanceRequest.create!(stable_coin:, user: current_user, request_id:, status: :created)

    # MEMO: この先本来非同期
    generate_block

    amount = tx.outputs[vout].value

    stable_coin_transaction = StableCoinTransaction.create(
      stable_coin:,
      amount:,
      txid:,
      transaction_type: :issue,
      transaction_time: Time.current
    )

    wallet = current_user.wallet
    wallet.update!(balance: wallet.balance + amount)
    wallet_transaction = WalletTransaction.create(
      wallet:,
      amount:,
      transaction_type: :deposit,
      transaction_time: Time.current
    )

    account = current_user.account
    account.update!(balance: account.balance - amount)
    account_transaction = AccountTransaction.create(
      account:,
      amount: -amount,
      transaction_type: :transfer,
      transaction_time: Time.current
    )

    # MEMO: CreateIssuanceTransactionService のなかで StableCoinTransaction/WalletTransaction/AccountTransaction を作りたい
    issuance_transaction = IssuanceTransaction.create!(
      amount:,
      txid:,
      stable_coin_transaction:,
      account_transaction:,
      wallet_transaction:,
      transaction_time: DateTime.current
    )

    request.update!(issuance_transaction:, status: :completed)

    redirect_to user_path, notice: "Issue successful."
  end

  private

  def deposit_params
    params.require(:stable_coin).permit(:amount)
  end
end
