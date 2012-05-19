Spree::OrderMailer.class_eval do
  def gift_card_email(card, order)
    @gift_card = card
    @order = order
    cc = (card.cc_me && card.sender) ? card.sender.email : []
    subject = t('spree_gift_card.messages.email_subject', :sender => card.sender_name)
    @gift_card.update_attribute(:sent_at, Time.now) unless @gift_card.sent_at?
    mail(:to => card.email, :cc => cc, :subject => subject)
  end
end
