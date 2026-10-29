class Provider < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :clients, through: :subscriptions
  has_many :journal_entries, through: :clients

  validates :name, :email, presence: true
  validates :email, uniqueness: true
end
