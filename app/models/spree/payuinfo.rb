class Spree::Payuinfo < ActiveRecord::Base
  attr_accessible :PaymentId, :TransactionId, :amount, :first_name, :last_name, :order_id, :user_id
  belongs_to:order
  belongs_to:user
end
