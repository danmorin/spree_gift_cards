class CreateGiftCards < ActiveRecord::Migration
  def self.up
    create_table :spree_gift_cards do |t|
      t.integer :variant_id, :null => false
      t.integer :line_item_id
      t.integer :user_id
      t.string :email, :null => false
      t.string :name
      t.text :note
      t.string :token, :null => false
      t.boolean :is_received, :default => false, :null => false
      t.string :delivery_method, :default => 'email'
      t.datetime :sent_at
      t.timestamps
    end
  end

  def self.down
    drop_table :spree_gift_cards
  end
end
