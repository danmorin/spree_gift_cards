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

  attr_accessible :name, :email, :sender_name, :note, :variant_id, :delivery_method

  scope :users_cards, lambda{|user_id| where("sender_id = ? OR recipient_id = ?", user_id, user_id).order('created_at desc')  }
  
  def self.remaining_credit(user_id)
     joins(:store_credit).where("recipient_id = ?", user_id).sum(:remaining_amount)
  end

  def price
    (self.line_item ? self.line_item.price * self.line_item.quantity : self.variant.price) || 0.0
  end

  def register(user)
    self.update_attribute(:is_received, true)
    self.update_attribute(:recipient, user)

    @sc = StoreCredit.create(:amount => self.price, :remaining_amount => self.price,
                       :reason => 'gift card', :user => user)
                       
    self.update_attribute(:store_credit_id, @sc.id)                 
  end

  private

	def generate_token
	  self.token = Digest::SHA1.hexdigest([Time.now, rand].join)
	end
end
