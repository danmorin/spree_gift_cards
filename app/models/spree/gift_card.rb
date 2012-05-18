module Spree
  class GiftCard < ActiveRecord::Base
    attr_accessor :amount
    
    attr_accessible :name, :email, :sender_name, :note, :variant_id, :delivery_method, :cc_me, :amount, :address
    
    before_validation :set_variant
    before_create :generate_token
    
    belongs_to :variant
    belongs_to :line_item
    belongs_to :sender, :class_name => "Spree::User"
    belongs_to :recipient, :class_name => "Spree::User"
    belongs_to :store_credit

    validates :email,           :presence => { if: :email_delivery? }, 
                                :email => { if: proc { email_delivery? && email? } }
    validates :address,         :presence => { if: :ship_delivery?}
    validates :name,            :presence => true
    validates :sender_name,     :presence => true
    validates :variant,         :presence => { :message => "Price option must be selected" }
    validates :delivery_method, :inclusion => { :in => %w{ email ship } }
    # validates :amount,          :presence => { :unless => :variant_id? },
    #                            :numericality => { :greater_than_or_equal_to => 1, :less_than_or_equal_to => 1500 },
    #                            :numericality => { :greater_than_or_equal_to => 150, :if => :ship_delivery?, :message => "must be at least $150 to be shipped" }
    validate :check_amount

    scope :users_cards, lambda { |user_id| 
      where("(sender_id = ? OR recipient_id = ?) AND sent_at IS NOT NULL", user_id, user_id).
      order('created_at desc')  
    }
  
    def email_delivery?
      delivery_method == "email"
    end
    
    def ship_delivery?
      delivery_method == "ship"
    end
    
    # Doing this manually since I couldn't find an easy way to check for different min values with
    # special error messages using standard validations
    def check_amount
      return errors.add(:amount, "is required") if amount.blank?
      num_amount = (Float(amount) != nil rescue false)
      return errors.add(:amount, "must be a number") if num_amount == false 
      return errors.add(:amount, "must be at least $1") if amount.to_f < 1.0
      return errors.add(:amount, "can not be more than $1500") if amount.to_f > 1500
      return errors.add(:amount, "mut be at least $150 to have it shipped") if amount.to_f < 150 && ship_delivery?
    end
  
    def self.remaining_credit(user_id)
       joins(:store_credit).where("recipient_id = ?", user_id).sum(:remaining_amount)
    end

    # Used for the final price of the purchased gift card
    def price
      if line_item
        line_item.price * line_item.quantity
      elsif variant
        variant.price
      else
        0.0
      end
    end
    
    # Used while setting the amount of the gift card
    def amount
      return @amount if @amount
      return variant.price if variant
    end

    def register(user)
      return false if ! purchased? || is_received?
      
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
    
    def assign_to_order(order)
      if line_item
        
        # If the variant is already correct we don't have to do anything
        return if line_item.variant == variant
        
        # If it's an old variant, we want to remove that line_item
        line_item.destroy if line_item.variant != variant
      end
      
      self.line_item = order.add_variant(self.variant, 1)
    end
    
    def options_text
      text = "To: #{name}" 
      text << " (#{email})" if email? && email_delivery?
      text
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
    
    def set_variant
      return if line_item && line_item.order.completed?
      return unless @amount && delivery_method?
      
      product = gift_card_product
      if product
        self.variant = find_or_create_variant(product, amount)
      else
        self.variant = nil
      end
    end
    
    # Find the correct product given the delivery method
    def gift_card_product
      Spree::Product.
        joins(:shipping_category).
        where(is_gift_card: true).
        where("LOWER(spree_shipping_categories.name) LIKE ?", "%#{delivery_method}%").
        first
    end
    
    def find_or_create_variant(product, amount)
      product.variants.find_or_create_by_retail_price(amount) do |v|
        v.on_hand = 1000000
      end
    end
  end
end
