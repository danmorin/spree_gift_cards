class AddAddressToSpreeGiftCards < ActiveRecord::Migration
  def change
    add_column :spree_gift_cards, :address, :text
  end
end
