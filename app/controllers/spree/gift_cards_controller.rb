module Spree
  class GiftCardsController < BaseController
    helper 'spree/admin/base'
    #before_filter :authenticate_user!, :only => :new
    
    def index
      redirect_to new_gift_card_path
    end
    
    def new
      find_gift_card_variants
      @gift_card = GiftCard.new
      #@gift_card.sender_name = [current_user.fname || "", " ", current_user.lname || ""].join
      #@gift_card.sender_name = current_user.email
      @gift_card.cc_me = true
    end

    def create
      @gift_card = GiftCard.new(params[:gift_card])
      if @gift_card.save
        @order = current_order(true)
        line_item = @order.add_variant(@gift_card.variant, 1)
        @gift_card.line_item = line_item
        @gift_card.sender = current_user
        @gift_card.save
        redirect_to cart_path
      else
        find_gift_card_variants
        render :action => :new
      end
    end

    def edit
      @gift_card = GiftCard.find_by_token(params[:id])
      access_forbidden unless @gift_card && @gift_card.sender == current_user
      if @gift_card.purchased?
        flash[:error] = t("spree_gift_card.messages.purchased_no_edit")
        return redirect_to root_url
      end
    end

    def update
      @gift_card = GiftCard.find_by_token(params[:id])
      access_forbidden unless @gift_card && @gift_card.sender == current_user && !@gift_card.is_received?
      
      if @gift_card.purchased?
        flash[:error] = t("spree_gift_card.messages.purchased_no_edit")
        return redirect_to root_url
      end
      
      params[:gift_card].delete(:variant_id)
      if @gift_card.update_attributes(params[:gift_card])

        # We don't want to resend them and we're not letting them update it after the order is complete
        # OrderMailer.gift_card_email(@gift_card, @gift_card.line_item.order).deliver if @gift_card.sent_at.present?

        flash[:notice] = t("spree_gift_card.messages.successfully_updated")
        redirect_to cart_path
      else
        render :action => :edit
      end
    end

    def activate
      @gift_card = GiftCard.find_by_token(params[:id])
      if @gift_card.is_received?
        flash[:error] = t("spree_gift_card.messages.cant_activate")
        return redirect_to root_url
      end
      
      unless @gift_card.purchased?
        flash[:error] = t("spree_gift_card.messages.invalid")
        return redirect_to root_url
      end

      if current_user && !current_user.anonymous?
        if @gift_card.register(current_user)
          flash[:notice] = t("spree_gift_card.messages.activated")
        else
          flash[:error] =  t("spree_gift_card.messages.register_error")
        end
      else
        #session[:gift_card] = @gift_card.token
        session["user_return_to"] = confirm_gift_card_path(@gift_card)
        flash[:notice] = t("spree_gift_card.messages.authorization_required")
      end
      redirect_to root_url
    end
  
    def preview
      @gift_card = GiftCard.new(:email => params[:email], :name => params[:name], :sender_name => params[:sender_name], :variant_id => params[:variant_id])
    end
  
    # Where a user goes to start the activation process
    def confirm
      @gift_card = GiftCard.find_by_token(params[:id])
      if @gift_card.is_received?
        flash[:error] = t("spree_gift_card.messages.cant_activate")
        return redirect_to root_url
      end
      
      unless @gift_card.purchased?
        flash[:error] = t("spree_gift_card.messages.invalid")
        return redirect_to root_url
      end
    
      if !current_user || current_user.anonymous?
        # session[:gift_card] = @gift_card.token
        session["user_return_to"] = confirm_gift_card_path(@gift_card)
        flash[:notice] = t("spree_gift_card.messages.authorization_required")
        redirect_to new_user_session_path
      # else 
         # session[:gift_card] = nil
      end
    
    end

    private

    def find_gift_card_variants
      @gift_card_variants = Variant.joins(:product).
                                where("spree_products.is_gift_card = ?", true).
                                where("spree_variants.price > ?", 0).
                                where("spree_variants.is_master = ?", false). # Assuming there will be variants
                                order("spree_variants.price")
    end
  end
end
