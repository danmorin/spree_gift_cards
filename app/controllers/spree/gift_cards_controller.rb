module Spree
  class GiftCardsController < BaseController
    helper 'spree/admin/base'
    #before_filter :authenticate_user!, :only => :new
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
      @gift_card = GiftCard.find(params[:id])
      access_forbidden unless @gift_card && @gift_card.sender == current_user
    end

    def update
      @gift_card = GiftCard.find(params[:id])
      access_forbidden unless @gift_card && @gift_card.sender == current_user && !@gift_card.is_received?
      params[:gift_card].delete(:variant_id)
      if @gift_card.update_attributes(params[:gift_card])
        OrderMailer.gift_card_email(@gift_card, @gift_card.line_item.order).deliver if @gift_card.sent_at.present?
        flash[:notice] = t("spree_gift_card.messages.successfully_updated")
        redirect_to account_url
      else
        render :action => :edit
      end
    end

    def activate
      @gift_card = GiftCard.find_by_token(params[:id])
      if @gift_card.is_received
        flash[:error] = t("gift_card_messages.cant_activate")
        redirect_to root_url
        return
      end

      if current_user && !current_user.anonymous?
        if @gift_card.register(current_user)
          flash[:notice] = t("spree_gift_card.messages.activated")
        else
          flash[:error] =  t("spree_gift_card.messages.register_error")
        end
      else
        session[:gift_card] = @gift_card.token
        flash[:notice] = t("spree_gift_card.messages.authorization_required")
      end
      redirect_to root_url
    end
  
    def preview
      @gift_card = GiftCard.new(:email => params[:email], :name => params[:name], :sender_name => params[:sender_name], :variant_id => params[:variant_id])
    end
  
    def confirm
      @gift_card = GiftCard.find_by_token(params[:id])
      if @gift_card.is_received
        flash[:error] = t("gift_card_messages.cant_activate")
        redirect_to root_url
        return
      end
    
      if !current_user || current_user.anonymous?
        session[:gift_card] = @gift_card.token
        flash[:notice] = t("spree_gift_card.messages.authorization_required")
        redirect_to root_url
      else 
         session[:gift_card] = nil
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
