require 'lib/action_view/helpers/js_helper'
require 'lib/action_view/template/handlers/rjs'
require 'lib/js-rails/rendering'

ActionView::Base.class_eval do
  cattr_accessor :debug_rjs
  self.debug_rjs = false
end

ActionView::Base.class_eval do
  include ActionView::Helpers::JsHelper
end

ActionView::TestCase.class_eval do
  include ActionView::Helpers::JsHelper
end

ActionView::Template.register_template_handler :rjs, ActionView::Template::Handlers::RJS.new
