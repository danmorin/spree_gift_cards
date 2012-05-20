Spree::Core::Engine.routes.prepend do
  resources :gift_cards do
    post :activate, :on => :member
    get :confirm, :on => :member
    
    collection do
      get :redeem
      post :claim
    end
  end
  
  match "redeem" => "gift_cards#redeem"
end
