class Todo < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :completed, inclusion: { in: [ true, false ] }
end
