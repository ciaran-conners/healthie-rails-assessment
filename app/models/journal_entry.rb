class JournalEntry < ApplicationRecord
  belongs_to :client
  validates :body, presence: true

  scope :chronological, ->(sort_order = :desc) { order(created_at: sort_order, id: sort_order) }
end
