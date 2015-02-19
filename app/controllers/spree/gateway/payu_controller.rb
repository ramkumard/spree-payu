require 'base64'
require 'digest/md5'
require 'ruby_rc4'

module Spree
  class Gateway::PayuController < Spree::StoreController
    include Spree::Core::ControllerHelpers::Order
    include Spree::Core::ControllerHelpers::Auth
    include ERB::Util
    include AffiliateCredits
    include EncryptionNewPG

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products'

    respond_to :html

    skip_before_filter :verify_authenticity_token, :only => [:comeback]

    NECESSARY = [
                 "Mode",
                 "PaymentID",
                 "DateCreated",
                 "MerchantRefNo",
                 "Amount",
                 "TransactionID",
                 "ResponseCode",
                 "ResponseMessage"
                ]


    # Show form EBS for pay
    #
    def show
      @order   = Spree::Order.find(params[:order_id])
      @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }
      @order.payments.destroy_all
      @hash = Digest::SHA512.hexdigest("#{@gateway.preferred_account_id}|#{@order.number}|#{@order.total}|StyletagProduct|#{@order.ship_address.try(:full_name)}|#{(@order.email || @order.user.try(:email))}|||||||||||#{@gateway.preferred_secret_key}")
      payment = @order.payments.create!(:amount => 0,  :payment_method_id => @gateway.id)

      if @order.blank? || @gateway.blank?
        flash[:error] = I18n.t("invalid_arguments")
        redirect_to :back
      else
        @bill_address, @ship_address =  @order.bill_address, (@order.ship_address || @order.bill_address)
        render :action => :show
      end
    end

    # Result from EBS
    #
    def comeback
      @order   = current_order || Spree::Order.find_by_number(params[:id])
      payment_method = Spree::PaymentMethod::Payu.where(:environment => Rails.env.to_s).first
      payment = @order.payments.where(:payment_method_id => payment_method.id).first
      payment = @order.payments.create!(:amount => 0,  :payment_method_id => payment_method.id) if payment.blank?
      @gateway = @order && @order.payments.first.payment_method
      if  (params["status"] == "success") &&
          (params["txnid"] == @order.number.to_s) &&
          (params["amount"].to_f == @order.outstanding_balance.to_f)
        payu_payment_success(params)
        @order.reload
        @order.next
        #~ @order.add_christmas_cashback_offer if @order && @order.state == "complete"
        session[:order_id] = nil
        #referal credits
        if !Spree::Affiliate.where(user_id: spree_current_user.id).empty? && (@order.state == 'complete') && spree_current_user.orders.complete.count==1
          sender=Spree::User.find(Spree::Affiliate.where(user_id: spree_current_user.id).first.partner_id)
          #create credit (if required)
          create_affiliate_credits(sender, spree_current_user, "purchase")
        end
        #@order.finalize!
        redirect_to order_url(@order, {:checkout_complete => true, :token => @order.token}), :notice => I18n.t("payment_success")
      else
        payu_error = params["error_Message"]
        flash[:error] = I18n.t("ebsin_payment_response_error")+" Payment: "+payu_error
        redirect_to (@order.blank? ? root_url : edit_order_url(@order, {:token => @order.token}))
      end



    end


    private

    # Completed payment process
    def payu_payment_success(data)
      # record the payment
      source = Spree::Payuinfo.create(:first_name => @order.bill_address.firstname, :last_name => @order.bill_address.lastname, :TransactionId => data["mihpayid"], :PaymentId => data["bank_ref_num"], :amount => data["amount"], :order_id => @order.id,:user_id =>@order.user_id)

      payment_method = Spree::PaymentMethod.where(:type => "Spree::PaymentMethod::Payu").last
      payment = @order.payments.where(:payment_method_id => payment_method.id).first
      payment = @order.payments.create!(:amount => 0,  :payment_method_id => payment_method.id) if payment.blank?
      payment.source = source
      payment.amount = source.amount
      payment.save
      payment.complete!
    end

  end
end
