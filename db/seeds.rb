# frozen_string_literal: true

issuer_did = Did.create!(short_form: 'did:ion:EiBp3cIdfnX0gCy1DeyGp9ukx7hUUUviwa54ILNhr0IqWg:eyJkZWx0YSI6eyJwYXRjaGVzIjpbeyJhY3Rpb24iOiJyZXBsYWNlIiwiZG9jdW1lbnQiOnsicHVibGljS2V5cyI6W3siaWQiOiJzaWduaW5nLWtleSIsInB1YmxpY0tleUp3ayI6eyJjcnYiOiJzZWNwMjU2azEiLCJrdHkiOiJFQyIsIngiOiJpRVBQYkZtN2ZEYXZmbGphdm45N3FvTTZuQmpNcGJwVGFWTVlWSThEcVNZIiwieSI6InkyMklCdXlfV3AxYm1BYTA4Y0o4UWhNQkpERkRTY1c5UGIxYVVVNE81UlkifSwicHVycG9zZXMiOlsiYXV0aGVudGljYXRpb24iXSwidHlwZSI6IkVjZHNhU2VjcDI1NmsxVmVyaWZpY2F0aW9uS2V5MjAxOSJ9XSwic2VydmljZXMiOltdfX1dLCJ1cGRhdGVDb21taXRtZW50IjoiRWlCYUUtOURZMkNqNVpqY3JpLUhGMllrekhmdTVEbGRmLWRpYXJQLWo2emNFZyJ9LCJzdWZmaXhEYXRhIjp7ImRlbHRhSGFzaCI6IkVpQXBUVzdKb1hBdkYxa3ZpOHRrZEpESG9rWThkc0RSdnZwU3Atc1NTS1FRemciLCJyZWNvdmVyeUNvbW1pdG1lbnQiOiJFaUI5WGQwQjlRbDRuRTlveFNGV1ZWWkRpUVBScnhkSDNVRXpSWXpFMHpWYllnIn19')
jwk = {
  "kty": "EC",
  "crv": "secp256k1",
  "x": "iEPPbFm7fDavfljavn97qoM6nBjMpbpTaVMYVI8DqSY",
  "y": "y22IBuy_Wp1bmAa08cJ8QhMBJDFDScW9Pb1aUU4O5RY",
  "d": "z4pvdh8NIQ2PIj7ExaAeyMIinznarIkxaTVToj_W-cw"
}
Key.create!(did: issuer_did, jwk: jwk.to_json)

# アンカリングだるいので long form
did = Did.create!(short_form: 'did:ion:EiDkFiteeLUdg6wpK7RnfxbRcl_45DMx-y6E869_1v9Pog:eyJkZWx0YSI6eyJwYXRjaGVzIjpbeyJhY3Rpb24iOiJyZXBsYWNlIiwiZG9jdW1lbnQiOnsicHVibGljS2V5cyI6W3siaWQiOiJzaWduaW5nLWtleSIsInB1YmxpY0tleUp3ayI6eyJjcnYiOiJzZWNwMjU2azEiLCJrdHkiOiJFQyIsIngiOiJBbTdkVjF2UTZGUU5reFRTNDI4MVVFdHB6anpNeG9yN0J0REt5cWVyMGN3IiwieSI6ImZHaU5BRXJJLWFWM00xT1AzaEo3VW81Sm5pWE00LVRMcGhtWENneG1veTAifSwicHVycG9zZXMiOlsiYXV0aGVudGljYXRpb24iXSwidHlwZSI6IkVjZHNhU2VjcDI1NmsxVmVyaWZpY2F0aW9uS2V5MjAxOSJ9XSwic2VydmljZXMiOltdfX1dLCJ1cGRhdGVDb21taXRtZW50IjoiRWlCNTllajJCZ2pDZTJwVFd5WDFmQ3VjaUVtcXVodW13d3NIM3ZRVE5IbFF4QSJ9LCJzdWZmaXhEYXRhIjp7ImRlbHRhSGFzaCI6IkVpRG5NMzJZeFpIUkEzZGxSZE9EelhZQ1g4MV9XTTg0TlRSb1E1RnJUY1p2WEEiLCJyZWNvdmVyeUNvbW1pdG1lbnQiOiJFaUEwMjJ2dlEtMGVEOE1qN2hTWV9lanpNbEFwOENDUDhHdzlqY2dhSkRhSnNRIn19')
user = User.create!(username: 'demo_user', did:)
Wallet.create!(user:, balance: 0)
account = Account.create!(user:, balance: 1000)
AccountTransaction.create(
  account:,
  amount: 1000,
  transaction_type: :deposit,
  transaction_time: Time.current
)

if Glueby::AR::SystemInformation.synced_block_height.nil?
  Glueby::AR::SystemInformation.create!(info_key: 'synced_block_number', info_value: '0')
end

address = Glueby::Internal::RPC.client.getnewaddress
aggregate_private_key = ENV['TAPYRUS_AUTHORITY_KEY']
Glueby::Internal::RPC.client.generatetoaddress(1, address, aggregate_private_key)

latest_block_num = Glueby::Internal::RPC.client.getblockcount
synced_block = Glueby::AR::SystemInformation.synced_block_height
(synced_block.int_value + 1..latest_block_num).each do |height|
  Glueby::BlockSyncer.new(height).run
  synced_block.update(info_value: height.to_s)
end
