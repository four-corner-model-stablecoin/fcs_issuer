class Did < ApplicationRecord
  belongs_to :user, optional: true
  has_many :contract

  validates :short_form, presence: true
end
