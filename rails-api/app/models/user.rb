class User < ApplicationRecord
  has_secure_password
  before_save :downcase_email

  #validations
  validates :email, presence: true, uniqueness: {case_sensitive: false}, format:  { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_digest_changed?

  private

  def downcase_email
    self.email = email.downcase
  end
end
