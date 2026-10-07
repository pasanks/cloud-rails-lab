# A note stored in the primary database (DATABASE_URL).
class Note < ApplicationRecord
  validates :title, presence: true
end
