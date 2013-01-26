require 'rails'
require 'active_support'

module JsRails
  class Engine < Rails::Engine
    initializer 'js-rails.initialize' do
      ActiveSupport.on_load(:action_controller) do
        require 'lib/js-rails/on_load_action_controller'
      end

      ActiveSupport.on_load(:action_view) do
        require 'lib/js-rails/on_load_action_view'
      end
    end
  end
end