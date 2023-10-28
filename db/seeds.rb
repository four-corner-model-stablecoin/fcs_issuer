# frozen_string_literal: true

issuer_did = Did.create!(short_form: 'did:ion:EiDEEa4KVslUqv74jb1gmlg8pkIOOKW5ENEZ4T0UkMsZWw')
jwk = {
  "kty": "EC",
  "crv": "secp256k1",
  "x": "Voj_8w4oaW6_6GklLeTejTBmuAQ_Z-Y6JarrwIG4Kxg",
  "y": "Fms2H01qPVrk4Ev066hsfA3_WykLUADe1hUEr0L08RY",
  "d": "fgHacwHITapItydAQ-KOgmFsHR_4lzQec8d4QYXuMsg"
}
Key.create!(did: issuer_did, jwk: jwk.to_json)

# アンカリングだるいので long form
did = Did.create!(short_form: 'did:ion:EiCWA7PcShXwBoRfgB3MwQRzHU9Il6Phpdvyk8lCoTB-fA:eyJkZWx0YSI6eyJwYXRjaGVzIjpbeyJhY3Rpb24iOiJyZXBsYWNlIiwiZG9jdW1lbnQiOnsicHVibGljS2V5cyI6W3siaWQiOiJzaWduaW5nLWtleSIsInB1YmxpY0tleUp3ayI6eyJjcnYiOiJzZWNwMjU2azEiLCJrdHkiOiJFQyIsIngiOiJKaWdkak53S19YX1d0a016Ny12MkpDSjhrcm40aHhLQmRjdWRJMHRrTnd3IiwieSI6IlFyTWZEc2otVW1JOHFQQUV4Tm0zQnlUY3U5anppSS1ENEdqd1NOZ2JTNjQifSwicHVycG9zZXMiOlsiYXV0aGVudGljYXRpb24iXSwidHlwZSI6IkVjZHNhU2VjcDI1NmsxVmVyaWZpY2F0aW9uS2V5MjAxOSJ9XSwic2VydmljZXMiOltdfX1dLCJ1cGRhdGVDb21taXRtZW50IjoiRWlBTzFCRDI5YmpIY09FbkdCV0RFaWNtcFNqNnVsLXZ3MEg2cHR1TVhCMFF3USJ9LCJzdWZmaXhEYXRhIjp7ImRlbHRhSGFzaCI6IkVpQTVXNmliN04zbzZKTjRyYkZjU1RJb0Q0OVZ0RloyUmdiV0tmNGZDZ1dfNXciLCJyZWNvdmVyeUNvbW1pdG1lbnQiOiJFaUIxbmFQcHBwREd4OTN3RXBuSG9PcDQ1S3dkT1RWeGs4c2RKcDVBbWgxa2ZnIn19')
user = User.create!(username: 'user', did:)
Wallet.create!(user:, balance: 0)
Account.create!(user:, balance: 1000)

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
