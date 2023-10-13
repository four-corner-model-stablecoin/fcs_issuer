class Contract < ApplicationRecord
  belongs_to :did
  has_one :stable_coin

  validates :script_pubkey, presence: true
  validates :redeem_script, presence: true
  validates :contracted_at, presence: true
  validates :effective_date, presence: true
  validates :expired_at, presence: true
end
