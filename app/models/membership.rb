class Membership < ApplicationRecord
  belongs_to :order_id
  belongs_to :customer_id
end
