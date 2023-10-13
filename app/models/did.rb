class Did < ApplicationRecord
  belongs_to :user
  has_many :contract

  validates :short_form, presence: true
end
