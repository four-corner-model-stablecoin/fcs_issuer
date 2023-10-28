# frozen_string_literal: true

class WithdrawsController < ApplicationController
  def create
    request_id = params[:request_id]
    brand_to_issuer_txid = params[:brand_to_issuer_txid]
    brand_to_issuer_tx = Tapyrus::Tx.parse_from_payload(Glueby::Internal::RPC.client.getrawtransaction(brand_to_issuer_txid).htb)

    request = WithdrawalRequest.create(request_id:, brand_to_issuer_txid:)

    # token outpoint
    # vout = 0 で決めうち
    token_outpoint = Tapyrus::OutPoint.from_txid(brand_to_issuer_txid, 0)
    token_output = brand_to_issuer_tx.outputs.first
    token_script_pubkey = token_output.script_pubkey
    color_identifier = token_script_pubkey.color_id
    stable_coin = StableCoin.find_by(color_id: color_identifier.to_payload.bth)

    # issuer key
    issuer_key = Tapyrus::Key.new(priv_key: stable_coin.contract.issuer_did.key.private_key, key_type: 0)

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
    generate_block

    request.update!(burn_txid:)

    # TODO: Transaction系の設計よく分からんのでパス

    render json: { burn_txid: }
  end

  def confirm
  end
end
