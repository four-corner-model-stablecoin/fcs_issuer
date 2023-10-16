# frozen_string_literal: true

Tapyrus.chain_params = :dev if ENV['TAPYRUS_CHAIN_PARAMS'] == 'dev'

Glueby.configure do |config|
  config.rpc_config = {
    schema: 'http',
    host: ENV['TAPYRUS_RPC_HOST'],
    port: ENV['TAPYRUS_RPC_PORT'],
    user: ENV['TAPYRUS_RPC_USER'],
    password: ENV['TAPYRUS_RPC_PASSWORD']
  }

  # Use ActiveRecord as wallet adapter
  config.wallet_adapter = :activerecord
end
