# frozen_string_literal: true

module Api
  class PaymentsController < ApplicationController
    def create
      tx_hex = params[:tx]
      vc = params[:vc]
      user_did = params[:user_did]
      user = Did.find_by(short_form: user_did).user
      stable_coin = StableCoin.last

      PaymentRequest.create!(request_id: params[:request_id], stable_coin:, user:, vc:, status: :created)

      # 顧客から受け取ったトランザクション
      tx = Tapyrus::Tx.parse_from_payload(tx_hex.htb)

      # TODO: Verify output

      # fill TPC as fee
      utxo = Glueby::Internal::RPC.client.listunspent.first
      tx.in << Tapyrus::TxIn.new(out_point: Tapyrus::OutPoint.from_txid(utxo['txid'], utxo['vout']))
      fee_tapyrus = (0.00003 * (10**8)).to_i
      input_tapyrus = (utxo['amount'].to_f * (10**8)).to_i
      change_tapyrus = input_tapyrus - fee_tapyrus
      tx.out << Tapyrus::TxOut.new(value: change_tapyrus, script_pubkey: Tapyrus::Script.parse_from_addr(Glueby::Internal::RPC.client.getnewaddress))

      # sign for TPC
      script_pubkey = Tapyrus::Script.parse_from_payload(utxo['scriptPubKey'].htb)
      key = Tapyrus::Key.from_wif(Glueby::Internal::RPC.client.dumpprivkey(script_pubkey.to_addr))
      sig_hash = tx.sighash_for_input(1, script_pubkey)
      sig = key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
      tx.in[1].script_sig << sig
      tx.in[1].script_sig << key.pubkey

      render json: { tx: tx.to_hex }
    end

    def confirm
      request = PaymentRequest.find_by!(request_id: params[:request_id])

      tx_hex = params[:tx]
      lock_script_hex = params[:lock_script]
      lock_script = Tapyrus::Script.parse_from_payload(lock_script_hex.htb)

      tx = Tapyrus::Tx.parse_from_payload(tx_hex.htb)

      # add sig for token
      issuer_key = Did.first.key.to_tapyrus_key
      sig_hash = tx.sighash_for_input(0, lock_script)
      sig = issuer_key.sign(sig_hash) + [Tapyrus::SIGHASH_TYPE[:all]].pack("C")
      tx.in[0].script_sig << sig

      txid = Glueby::Internal::RPC.client.sendrawtransaction(tx.to_payload.bth)
      request.update!(status: :transfering)

      # MEMO: 本来は非同期に実行、デモではgenerate_blockを用いて同期的に実行
      generate_block

      amount = tx.outputs.first.value

      # 顧客ウォレットを操作
      wallet = request.user.wallet
      wallet.update!(balance: wallet.balance - amount)
      wallet_transaction = WalletTransaction.create!(
        wallet:,
        amount: -amount ,
        transaction_type: :transfer,
        transaction_time: Time.current
      )

      # 送金履歴作成
      payment_transaction = PaymentTransaction.create!(
        wallet_transaction:,
        amount:,
        txid:,
        vc: request.vc,
        transaction_time: DateTime.current
      )

      request.update!(payment_transaction:, status: :completed)

      render json: { txid: }
    end
  end
end
