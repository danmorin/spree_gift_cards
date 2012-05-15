# Spree::UserSessionsController.class_eval do
#   after_filter :register_gift_card, :only => :create
# 
#   private
# 
#   def register_gift_card
#     return if session[:gift_card].nil? or current_user.nil?
#     redirect_to confirm_gift_card_path(session[:gift_card]) and return
#   end
# end
