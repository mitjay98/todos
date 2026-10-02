class User < ApplicationRecord
  has_secure_password
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  has_many :todos, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
