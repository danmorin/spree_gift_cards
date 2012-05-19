Spree::Core::Engine.routes.prepend do
  resources :gift_cards do
    post :activate, :on => :member
    get :confirm, :on => :member
  end
end
