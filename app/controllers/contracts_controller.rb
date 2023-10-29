# frozen_string_literal: true

class ContractsController < ApplicationController
  def new; end

  def create
    issuer_did = Did.first

    # brandへ契約リクエストを送る
    json = {
      name: 'tapyrus_issuer',
      did: issuer_did.short_form,
    }.to_json
    response = Net::HTTP.post(
    URI("#{ENV['BRAND_URL']}/contracts/agreement/issuer"),
    json,
    'Content-Type' => 'application/json'
    )
    body = JSON.parse(response.body)

    # 返答を受け取る
    brand_did_short_form = body['brand_did']
    color_id = body['color_id']
    redeem_script = body['redeem_script']
    script_pubkey = body['script_pubkey']
    contracted_at = body['contracted_at']
    effect_at = body['effect_at']
    expire_at = body['expire_at']

    brand_did = Did.find_or_create_by(short_form: brand_did_short_form)
    contract_with_brand = Contract.create(issuer_did:, brand_did:, redeem_script:, script_pubkey:, contracted_at:, effect_at:, expire_at:)
    StableCoin.create(contract: contract_with_brand, color_id:)
    redirect_to root_path
  end
end
