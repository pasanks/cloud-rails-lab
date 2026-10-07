# A note stored in the secondary database (SECONDARY_DATABASE_URL).
class SecondaryNote < SecondaryRecord
  validates :title, presence: true
end
