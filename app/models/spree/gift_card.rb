module Spree
  class GiftCard < ActiveRecord::Base
    belongs_to :variant
    belongs_to :line_item
    belongs_to :sender, :class_name => "User"
    belongs_to :recipient, :class_name => "User"
    belongs_to :store_credit

    validates :email, :presence => true, :email => true
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
    
    def token_formatted
      token.scan(/.{1,5}/).join("-")
    end
    
    # Find the gift card using a token that may include formatting
    def self.find_by_token(token)
      where(:token => token.gsub(/[^0-9a-z]/i, '').upcase).first!
    end
    
    def to_param
      token_formatted
    end
    
    def purchased?
      line_item && line_item.order.complete?
    end

    private

    def generate_token
      chars = %w{A C D E F G H J K L M N P R S T U V W X Y Z 2 3 4 5 6 7 9}
      
      record = true
      while record
        random = (1..15).collect{|a| chars[rand(chars.size)] }.join
        record = self.class.where(:token => random).exists?
      end
      self.token = random
    end
  end
end
