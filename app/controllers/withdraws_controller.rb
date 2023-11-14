# frozen_string_literal: true

class WithdrawsController < ApplicationController
  def create
    request_id = params[:request_id]
    amount = params[:amount]
    merchant_to_brand_txid = params[:merchant_to_brand_txid]
    brand_to_issuer_txid = params[:brand_to_issuer_txid]
    brand_to_issuer_tx = Tapyrus::Tx.parse_from_payload(Glueby::Internal::RPC.client.getrawtransaction(brand_to_issuer_txid).htb)

    # token outpoint
    # vout = 0 で決めうち
    token_outpoint = Tapyrus::OutPoint.from_txid(brand_to_issuer_txid, 0)
    token_output = brand_to_issuer_tx.outputs.first
    token_script_pubkey = token_output.script_pubkey
    color_identifier = token_script_pubkey.color_id
    stable_coin = StableCoin.find_by(color_id: color_identifier.to_payload.bth)

    request = WithdrawalRequest.create!(request_id:, stable_coin:, amount:, merchant_to_brand_txid:, brand_to_issuer_txid:, status: :created)

    # issuer key
    issuer_key = Did.first.key.to_tapyrus_key

    tx = Tapyrus::Tx.new

    # fill token
    tx.in << Tapyrus::TxIn.new(out_point: token_outpoint)

    # fill TPC as fee
    utxo = Glueby::Internal::RPC.client.listunspent.first
    tx.in << Tapyrus::TxIn.new(out_point: Tapyrus::OutPoint.from_txid(utxo['txid'], utxo['vout']))
    fee_tapyrus = (0.00003 * (10**8)).to_i
    input_tapyrus = (utxo['amount'].to_f * (10**8)).to_i
    change_tapyrus = input_tapyrus - fee_tapyrus
    tx.out << Tapyrus::TxOut.new(value: change_tapyrus, script_pubkey: Tapyrus::Script.parse_from_addr(Glueby::Internal::RPC.client.getnewaddress))

    # sign for token
    sig_hash = tx.sighash_for_input(0, token_script_pubkey)
    sig = issuer_key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
    tx.in[0].script_sig << sig
    tx.in[0].script_sig << issuer_key.pubkey

    # sign for TPC
    script_pubkey = Tapyrus::Script.parse_from_payload(utxo['scriptPubKey'].htb)
    key = Tapyrus::Key.from_wif(Glueby::Internal::RPC.client.dumpprivkey(script_pubkey.to_addr))
    sig_hash = tx.sighash_for_input(1, script_pubkey)
    sig = key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
    tx.in[1].script_sig << sig
    tx.in[1].script_sig << key.pubkey

    burn_txid = Glueby::Internal::RPC.client.sendrawtransaction(tx.to_payload.bth)

    request.update!(burn_txid:, status: :transfering)

    # MEMO: 本来は非同期に実行、デモではgenerate_blockを用いて同期実行
    # if ENV['DEMO'] = 1
    generate_block

    amount = request.amount

    stable_coin_transaction = StableCoinTransaction.create!(
      stable_coin:,
      amount: -amount,
      txid: burn_txid,
      transaction_type: :burn,
      transaction_time: Time.current
    )

    withdrawal_transaction = WithdrawalTransaction.create!(
      stable_coin_transaction:,
      amount:,
      merchant_to_brand_txid: request.merchant_to_brand_txid,
      brand_to_issuer_txid: request.brand_to_issuer_txid,
      burn_txid:,
      transaction_time: DateTime.current
    )

    request.update!(withdrawal_transaction:, status: :completed)

    render json: { burn_txid: }
  end

  def confirm
  end
end
