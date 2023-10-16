# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

issuer_did = Did.create(short_form: 'did:ion:EiDEEa4KVslUqv74jb1gmlg8pkIOOKW5ENEZ4T0UkMsZWw')
Key.create(did: issuer_did, private_key: '7e01da7301c84daa48b7274043e28e82616c1d1ff897341e73c7784185ee32c8')

user = User.create(username: 'user')
# long_formです
did = Did.create(user:, short_form: 'did:ion:EiCD3ZwzP67DZxQXsxfno0sGRQyg9GIFqzyB86L9dq9B5A:eyJkZWx0YSI6eyJwYXRjaGVzIjpbeyJhY3Rpb24iOiJyZXBsYWNlIiwiZG9jdW1lbnQiOnsicHVibGljS2V5cyI6W3siaWQiOiJzaWduaW5nLWtleSIsInB1YmxpY0tleUp3ayI6eyJjcnYiOiJzZWNwMjU2azEiLCJrdHkiOiJFQyIsIngiOiJSRzl3R3Q2WTNyMWtfQldKWlNnY1ZqemlmQTFkTmZMS01ZckZ0NVI4VVRFIiwieSI6IjFtWU1TX1lmenh3TEd6QWttb3Y0cG1Jd05JQ1RCa3duTllZeFlVbmxBYTgifSwicHVycG9zZXMiOlsiYXV0aGVudGljYXRpb24iXSwidHlwZSI6IkVjZHNhU2VjcDI1NmsxVmVyaWZpY2F0aW9uS2V5MjAxOSJ9XSwic2VydmljZXMiOlt7ImlkIjoiaG9nZSIsInNlcnZpY2VFbmRwb2ludCI6Imh0dHBzOi8vd3d3LnNobW43aWlpLm5ldC93YWxsZXQvaGdvYWllcmJndjtvZXVyZ2IiLCJ0eXBlIjoiZnVnYSJ9XX19XSwidXBkYXRlQ29tbWl0bWVudCI6IkVpQkU4SmM1eTdZUEhNNDBreDJEdHlPVWRpOE45T3BPS2YxRmdOY19ZaU4td0EifSwic3VmZml4RGF0YSI6eyJkZWx0YUhhc2giOiJFaUFLWWhoTmpGNk9templOXltZE5rWF9fYU9hZDVVbE9pTVZkNGdTeGFQSUhRIiwicmVjb3ZlcnlDb21taXRtZW50IjoiRWlCR3d0VkpRdXJOeW83ZF9DZ050VmJ4TFZYVk95cGxhdU1uZnl6Umc0MXhyUSJ9fQ')
Wallet.create(user:, balance: 0)
Account.create(user:, balance: 1000, account_number: '1234567', branch_code: '123', branch_name: 'hoge支店')
Key.create(did:, private_key: 'c9b574b398a5e4d8dbaa1914b3ef271611d7c914cf67709f420833c72f7c343e')

if Glueby::AR::SystemInformation.synced_block_height.nil?
  Glueby::AR::SystemInformation.create(info_key: 'synced_block_number', info_value: '0')
end

address =  Glueby::Internal::RPC.client.getnewaddress
aggregate_private_key = ENV['TAPYRUS_AUTHORITY_KEY']
Glueby::Internal::RPC.client.generatetoaddress(1, address, aggregate_private_key)

latest_block_num = Glueby::Internal::RPC.client.getblockcount
synced_block = Glueby::AR::SystemInformation.synced_block_height
(synced_block.int_value + 1..latest_block_num).each do |height|
  Glueby::BlockSyncer.new(height).run
  synced_block.update(info_value: height.to_s)
end
