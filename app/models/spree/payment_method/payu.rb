class Spree::PaymentMethod::Payu < Spree::PaymentMethod
  attr_accessible :preferred_account_id, :preferred_url, :preferred_secret_key, :preferred_mode, :preferred_currency_code

  preference :account_id, :string
  preference :url,        :string, :default =>  "https://secure.payu.in/_payment"
  preference :secret_key, :string
  preference :mode, :string
  preference :currency_code, :string

  attr_accessible :preferred_account_id, :preferred_url, :preferred_secret_key, :preferred_mode, :preferred_currency_code

  def payment_profiles_supported?
    false
  end

  def payment_source_class
    Payu
  end

end
