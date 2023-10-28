# frozen_string_literal: true

class User < ApplicationRecord
  validates :username, presence: true, length: { maximum: 255 }, uniqueness: true

  has_one :account
  has_one :wallet
  belongs_to :did
end
