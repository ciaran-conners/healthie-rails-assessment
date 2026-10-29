class Client < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :providers, through: :subscriptions
  has_many :journal_entries, dependent: :destroy

  validates :name, :email, presence: true
  validates :email, uniqueness: true
end
