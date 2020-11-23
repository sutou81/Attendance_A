class Office < ApplicationRecord
  validates :office_number,  presence: true, length: { maximum: 6 }, numericality: {only_integer: true}, uniqueness: true
  validates :office_name,  presence: true, length: { maximum: 20 }, uniqueness: true
end
