require 'spree_core'
require 'spree_payu/engine'

module SpreePayu
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    initializer "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods += [Spree::PaymentMethod::Payu]
    end
    
    config.to_prepare &method(:activate).to_proc
  end
end
