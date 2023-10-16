# frozen_string_literal: true

# userの秘密鍵モデル
class Key < ApplicationRecord
  belongs_to :did, optional: true
end
