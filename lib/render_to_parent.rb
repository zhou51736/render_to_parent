require "render_to_parent/version"
require 'rails'
require 'active_support'

module RenderToParent
  class Engine < Rails::Engine
    initializer 'js-rails.initialize' do
      ActiveSupport.on_load(:action_controller) do
        require 'render_to_parent/js-rails/on_load_action_controller'
      end

      ActiveSupport.on_load(:action_view) do
        require 'render_to_parent/js-rails/on_load_action_view'
      end
    end
  end
end
