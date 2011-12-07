if Product.where(:is_gift_card => true).count == 0
  puts "\tCreating default gift card..."
  product = Product.new(:name => "Gift Card", :is_gift_card => true, :price => 0)
  option_type = OptionType.new(:name => "is-gift-card", :presentation => "Gift Card")
  option_type.option_values << OptionValue.new(:name => "true")
  product.option_types << option_type
  product.variants = [25, 50, 75, 100].map{|amount| Variant.new(:price => amount)}
  product.variants.map{|v| v.option_values << option_type.option_values}
  product.save
end
