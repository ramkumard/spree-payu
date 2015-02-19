Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :gateway do
    get '/:gateway_id/payu/:order_id' => 'payu#show',     :as => :payu
    match '/payu/:id/comeback'          => 'payu#comeback', :as => :payu_comeback
  end
end
