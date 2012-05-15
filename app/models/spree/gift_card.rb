module Spree
  class GiftCard < ActiveRecord::Base
    belongs_to :variant
    belongs_to :line_item
    belongs_to :sender, :class_name => "User"
    belongs_to :recipient, :class_name => "User"
    belongs_to :store_credit

    validates :email, :presence => true
    validates :name, :presence => true
    validates :sender_name, :presence => true
    validates :variant, :presence => {:message => "Price option must be selected"}

    before_create :generate_token

    attr_accessible :name, :email, :sender_name, :note, :variant_id, :delivery_method, :cc_me

    scope :users_cards, lambda { |user_id| 
      where("(sender_id = ? OR recipient_id = ?) AND sent_at IS NOT NULL", user_id, user_id).
      order('created_at desc')  
    }
  
    def self.remaining_credit(user_id)
       joins(:store_credit).where("recipient_id = ?", user_id).sum(:remaining_amount)
    end

    def price
      # self.line_item || self.variant ? (self.line_item ? self.line_item.price * self.line_item.quantity : self.variant.price) : 0.0
    
      if line_item
        line_item.price * line_item.quantity
      elsif variant
        variant.price
      else
        0.0
      end
    end

    def register(user)
      @sc = StoreCredit.create(:amount => price, :remaining_amount => price,
                                  :reason => 'gift card', :user => user)
    
      self.is_received      = true
      self.recipient        = user
      self.store_credit_id  = @sc.id
      self.save
    end

    private

    def generate_token
      self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
    end
  end
end
