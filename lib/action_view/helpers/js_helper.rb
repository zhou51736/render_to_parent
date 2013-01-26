require 'set'
require 'active_support/json'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/output_safety'

module ActionView
  module Helpers
    #=====JsHelper start
    module JsHelper
      # All the methods were moved to GeneratorMethods so that
      # #include_helpers_from_context has nothing to overwrite.
      class JavaScriptGenerator #:nodoc:
        def initialize(context, &block) #:nodoc:
          @context, @lines = context, []
          include_helpers_from_context
          @context.with_output_buffer(@lines) do
            @context.instance_exec(self, &block)
          end
        end

        private
        def include_helpers_from_context
          extend @context.helpers if @context.respond_to?(:helpers) && @context.helpers
          extend GeneratorMethods
        end

        # JavaScriptGenerator generates blocks of JavaScript code that allow you
        # to change the content and presentation of multiple DOM elements.  Use
        # this in your Ajax response bodies, either in a <tt>\<script></tt> tag
        # or as plain JavaScript sent with a Content-type of "text/javascript".
        #
        # Create new instances with PrototypeHelper#update_page or with
        # ActionController::Base#render, then call +insert_html+, +replace_html+,
        # +remove+, +show+, +hide+, +visual_effect+, or any other of the built-in
        # methods on the yielded generator in any order you like to modify the
        # content and appearance of the current page.
        #
        # Example:
        #
        #   # Generates:
        #   #     new Element.insert("list", { bottom: "<li>Some item</li>" });
        #   #     new Effect.Highlight("list");
        #   #     ["status-indicator", "cancel-link"].each(Element.hide);
        #   update_page do |page|
        #     page.insert_html :bottom, 'list', "<li>#{@item.name}</li>"
        #     page.visual_effect :highlight, 'list'
        #     page.hide 'status-indicator', 'cancel-link'
        #   end
        #
        #
        # Helper methods can be used in conjunction with JavaScriptGenerator.
        # When a helper method is called inside an update block on the +page+
        # object, that method will also have access to a +page+ object.
        #
        # Example:
        #
        #   module ApplicationHelper
        #     def update_time
        #       page.replace_html 'time', Time.now.to_s(:db)
        #       page.visual_effect :highlight, 'time'
        #     end
        #   end
        #
        #   # Controller action
        #   def poll
        #     render(:update) { |page| page.update_time }
        #   end
        #
        # Calls to JavaScriptGenerator not matching a helper method below
        # generate a proxy to the JavaScript Class named by the method called.
        #
        # Examples:
        #
        #   # Generates:
        #   #     Foo.init();
        #   update_page do |page|
        #     page.foo.init
        #   end
        #
        #   # Generates:
        #   #     Event.observe('one', 'click', function () {
        #   #       $('two').show();
        #   #     });
        #   update_page do |page|
        #     page.event.observe('one', 'click') do |p|
        #      p[:two].show
        #     end
        #   end
        #
        # You can also use PrototypeHelper#update_page_tag instead of
        # PrototypeHelper#update_page to wrap the generated JavaScript in a
        # <tt>\<script></tt> tag.
        module GeneratorMethods
          def to_s #:nodoc:
            #(@lines * $/).tap do |javascript|
            (@lines.map(&:to_s) * $/).tap do |javascript|
              if ActionView::Base.debug_rjs
                source = javascript.dup
                javascript.replace "try {\n#{source}\n} catch (e) "
                javascript << "{ alert('RJS error:\\n\\n' + e.toString()); alert('#{source.gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }}'); throw e }"
              end
            end
          end

          # Returns an object whose <tt>to_json</tt> evaluates to +code+. Use this to pass a literal JavaScript
          # expression as an argument to another JavaScriptGenerator method.
          def literal(code)
            ::ActiveSupport::JSON::Variable.new(code.to_s)
          end

          # Displays an alert dialog with the given +message+.
          #
          # Example:
          #
          #   # Generates: alert('This message is from Rails!')
          #   page.alert('This message is from Rails!')
          def alert(message)
            call 'alert', message
          end

          # Redirects the browser to the given +location+ using JavaScript, in the same form as +url_for+.
          #
          # Examples:
          #
          #  # Generates: window.location.href = "/mycontroller";
          #  page.redirect_to(:action => 'index')
          #
          #  # Generates: window.location.href = "/account/signup";
          #  page.redirect_to(:controller => 'account', :action => 'signup')
          def redirect_to(location)
            url = location.is_a?(String) ? location : @context.url_for(location)
            record "window.location.href = #{url.inspect}"
          end

          # Reloads the browser's current +location+ using JavaScript
          #
          # Examples:
          #
          #  # Generates: window.location.reload();
          #  page.reload
          def reload
            record 'window.location.reload()'
          end

          # Calls the JavaScript +function+, optionally with the given +arguments+.
          #
          # If a block is given, the block will be passed to a new JavaScriptGenerator;
          # the resulting JavaScript code will then be wrapped inside <tt>function() { ... }</tt>
          # and passed as the called function's final argument.
          #
          # Examples:
          #
          #   # Generates: Element.replace(my_element, "My content to replace with.")
          #   page.call 'Element.replace', 'my_element', "My content to replace with."
          #
          #   # Generates: alert('My message!')
          #   page.call 'alert', 'My message!'
          #
          #   # Generates:
          #   #     my_method(function() {
          #   #       $("one").show();
          #   #       $("two").hide();
          #   #    });
          #   page.call(:my_method) do |p|
          #      p[:one].show
          #      p[:two].hide
          #   end
          def call(function, *arguments, &block)
            record "#{function}(#{arguments_for_call(arguments, block)})"
          end

          # Assigns the JavaScript +variable+ the given +value+.
          #
          # Examples:
          #
          #  # Generates: my_string = "This is mine!";
          #  page.assign 'my_string', 'This is mine!'
          #
          #  # Generates: record_count = 33;
          #  page.assign 'record_count', 33
          #
          #  # Generates: tabulated_total = 47
          #  page.assign 'tabulated_total', @total_from_cart
          #
          def assign(variable, value)
            record "#{variable} = #{javascript_object_for(value)}"
          end

          # Writes raw JavaScript to the page.
          #
          # Example:
          #
          #  page << "alert('JavaScript with Prototype.');"
          def <<(javascript)
            @lines << javascript
          end

          # Executes the content of the block after a delay of +seconds+. Example:
          #
          #   # Generates:
          #   #     setTimeout(function() {
          #   #     ;
          #   #     new Effect.Fade("notice",{});
          #   #     }, 20000);
          #   page.delay(20) do
          #     page.visual_effect :fade, 'notice'
          #   end
          def delay(seconds = 1)
            record "setTimeout(function() {\n\n"
            yield
            record "}, #{(seconds * 1000).to_i})"
          end

          private
          def loop_on_multiple_args(method, ids)
            record(ids.size>1 ?
                "#{javascript_object_for(ids)}.each(#{method})" :
                "#{method}(#{javascript_object_for(ids.first)})")
          end

          def page
            self
          end

          def record(line)
            line = "#{line.to_s.chomp.gsub(/\;\z/, '')};"
            self << line
            line
          end

          def render(*options)
            with_formats(:html) do
              case option = options.first
              when Hash
                @context.render(*options)
              else
                option.to_s
              end
            end
          end

          def with_formats(*args)
            return yield unless @context

            lookup = @context.lookup_context
            begin
              old_formats, lookup.formats = lookup.formats, args
              yield
            ensure
              lookup.formats = old_formats
            end
          end

          def javascript_object_for(object)
            ::ActiveSupport::JSON.encode(object)
          end

          def arguments_for_call(arguments, block = nil)
            arguments << block_to_function(block) if block
            arguments.map { |argument| javascript_object_for(argument) }.join ', '
          end

          def block_to_function(block)
            generator = self.class.new(@context, &block)
            literal("function() { #{generator.to_s} }")
          end

          def method_missing(method, *arguments)
            proxy = JavaScriptGeneratorScope.new(self, method.to_s, *arguments)
            @lines << proxy
            proxy
            #JavaScriptProxy.new(self, method.to_s.camelize)
          end
        end
      end

      class JavaScriptGeneratorScope < JavaScriptGenerator
        def initialize(generator, method, *arguments)
          @generator = generator
          @methods = [[method, arguments]]
          self
        end

        def to_s
          js = []
          @methods.each do |method, args|
            js << "#{method}(#{arguments_for_call(args)})"
          end
          record(js.join("."))
        end

        private
        def method_missing(method, *arguments)
          @methods << [method, arguments]
          self
        end

        def record(line)
          "#{line.to_s.chomp.gsub(/\;\z/, '')};"
        end

        def javascript_object_for(object)
          object.respond_to?(:to_json) ? object.to_json : object.inspect
        end

        def arguments_for_call(arguments, block = nil)
          arguments << block_to_function(block) if block
          arguments.map { |argument| javascript_object_for(argument) }.join ', '
        end

        def block_to_function(block)
          generator = self.class.new(@context, &block)
          literal("function() { #{generator.to_s} }")
        end
      end

      # Yields a JavaScriptGenerator and returns the generated JavaScript code.
      # Use this to update multiple elements on a page in an Ajax response.
      # See JavaScriptGenerator for more information.
      #
      # Example:
      #
      #   update_page do |page|
      #     page.hide 'spinner'
      #   end
      def update_page(&block)
        JavaScriptGenerator.new(self, &block).to_s.html_safe
      end

      # Works like update_page but wraps the generated JavaScript in a
      # <tt>\<script></tt> tag. Use this to include generated JavaScript in an
      # ERb template. See JavaScriptGenerator for more information.
      #
      # +html_options+ may be a hash of <tt>\<script></tt> attributes to be
      # passed to ActionView::Helpers::JavaScriptHelper#javascript_tag.
      def update_page_tag(html_options = {}, &block)
        javascript_tag update_page(&block), html_options
      end

    end
    #=====JsHelper end
  end
end
