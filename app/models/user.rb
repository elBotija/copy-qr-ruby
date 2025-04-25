class User < ApplicationRecord
  devise :database_authenticatable, :confirmable, :lockable, :registerable,
    :recoverable, :rememberable, :timeoutable, :validatable

  has_many :memorials

  validates :email, presence: true, uniqueness: true
  validates :terms_of_service, acceptance: true
end
