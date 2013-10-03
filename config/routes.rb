DdeServer::Application.routes.draw do
 
  resources :users

  resources :sites do
    collection do
      get :index_remote
    end
  end

  resources :npid_requests do
    collection do
      post :get_npids, :ack, :get_npids_in_batch, :acknowledge, :save_requested_ids
      get :get_npids, :ack, :get_npids_in_batch, :acknowledge, :save_requested_ids
    end
  end

  resources :npid_auto_generations do
    collection do
      post :master_available_npids, :create_npids
      get :master_available_npids, :create_npids
    end
  end

  resources :national_patient_identifiers do
    collection do
      get  'site/:site_id', :action => :for_site, :as => :site_specific
    end
  end

  resources :people do
    member do
      get :remote, :action => :show_remote 
    end

    collection do
      post :sync_demographics_with_master, :sync_demographics_with_proxy, 
           :sync_demographics_with_client,:find, :proxy_people_to_sync, 
           :demographics_to_sync, :master_people_to_sync, :record_successful_sync,
           :replace_national_id, :post_back_person, :record_sync_starttime, 
           :find_demographics, :create_footprint, :push_footprints,:create_for_sub_proxy,
           :push_demographics_to_traditional_authority,:acknowledge_traditional_authority_push
      get :find, :sync_demographics_with_master, :sync_demographics_with_proxy, 
          :sync_demographics_with_client, :proxy_people_to_sync, :demographics_to_sync, 
          :master_people_to_sync, :record_successful_sync,:replace_national_id,
          :reassign_identication, :post_back_person, :record_sync_starttime, 
          :find_demographics, :create_footprint, :push_footprints,:create_for_sub_proxy,
          :push_demographics_to_traditional_authority,:acknowledge_traditional_authority_push
    end
  end

  resource :login do
    collection do
      get :logout
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  root :to => 'logins#show'
end
