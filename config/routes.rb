CaerusGeo::Application.routes.draw do

  resources :surveys do
      resources :open
      resources :reports do
        resources :spresults
      end
      resources :collaborators
  end

  root :to => "home#index"

  devise_for :users
  
  resources :users, :only => [:show]

  match 'surveys/:id/export_blank_results', :to => 'surveys#export_blank_results', :as => :survey_export_blank_results, :via => :get

  match 'surveys/:id/export_csv', :to => 'surveys#export_results_csv', :as => :survey_results_csv, :via => :get
  match 'surveys/:id/export_csv_template', :to => 'surveys#export_csv_template', :as => :survey_export_csv_template, :via => :get
  match 'surveys/:id/export_all_results_pdf', :to => 'surveys#export_all_results_pdf', :as => :survey_export_all_results_pdf, :via => :get
  match 'surveys/:id/export_geojson', :to => 'surveys#export_results_geojson', :as => :survey_export_results_geojson, :via => :get

  match 'surveys/:id/results', :to => 'surveys#survey_results_pdf', :as => :survey_results_pdf, :via => :get
  match 'surveys/:id/analyze', :to => 'surveys#analyze', :as => :survey_analyze, :via => :get
  match 'surveys/:id/public', :to => 'surveys#public', :as => :survey_public, :via => :get

  match 'surveys/:survey_id/reports/:id/export_csv', :to => 'reports#export_csv', :as => :report_export_csv, :via => :get
  
  match 'surveys/:survey_id/reports/:id/export_geojson', :to => 'reports#export_results_geojson', :as => :report_export_results_geojson, :via => :get

  match 'surveys/:survey_id/reports/:id/results', :to => 'reports#export_results_pdf', :as => :export_results_pdf, :via => :get
  
  match 'surveys/:id/print_atlas', :to => 'surveys#print_atlas', :as => :survey_print_atlas, :via => :get
  match 'surveys/:id/print_wallmap', :to => 'surveys#print_wallmap', :as => :survey_print_wallmap , :via => :get

  match 'surveys/:id/all_entries', :to => 'surveys#all_entries', :as => :survey_all_entries , :via => :get
  match 'surveys/:survey_id/reports/:id/all_entries', :to => 'reports#all_entries', :as => :report_all_entries, :via => :get

  match '/about' => 'home#about'
  match '/terms' => 'home#terms'
  match '/how_it_works' => 'home#how_it_works'
  match '/error' => 'home#error', :as => :error_page
  match '/team' => 'home#team'
  match '/contact' => 'home#contact'

end
