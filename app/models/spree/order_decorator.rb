module Spree
  Order.class_eval do
  
    Spree::Order.state_machines[:state].after_transition :to => 'complete', :do => :finalize_with_gift_card!
  
    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize_with_gift_card!
      self.line_items.each do |li|
        if li.gift_card 
          # Make sure user is correct. They may not be if it was created as an
          # anonymous user and then they registered at checkout
          li.gift_card.sender = self.user
          li.gift_card.save
          
          if li.gift_card.delivery_method == 'email'
            OrderMailer.delay.gift_card_email(li.gift_card, self)
          end
        end
      end
    end

    def contains?(variant)
      return false if variant.product.is_gift_card?
      line_items.detect { |line_item| line_item.variant_id == variant.id }
    end
  end
end
