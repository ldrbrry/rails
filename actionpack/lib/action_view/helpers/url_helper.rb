module ActionView
  module Helpers
    # Provides a set of methods for making easy links and getting urls that depend on the controller and action. This means that
    # you can use the same format for links in the views that you do in the controller. The different methods are even named
    # synchronously, so link_to uses that same url as is generated by url_for, which again is the same url used for
    # redirection in redirect_to.
    module UrlHelper
      # Returns the URL for the set of +options+ provided. This takes the same options 
      # as url_for. For a list, see the url_for documentation in link:classes/ActionController/Base.html#M000079.
      def url_for(options = {}, *parameters_for_method_reference)
        if Hash === options then options = { :only_path => true }.update(options.stringify_keys) end
        @controller.send(:url_for, options, *parameters_for_method_reference)
      end

      # Creates a link tag of the given +name+ using an URL created by the set of +options+. See the valid options in
      # link:classes/ActionController/Base.html#M000021. It's also possible to pass a string instead of an options hash to
      # get a link tag that just points without consideration. If nil is passed as a name, the link itself will become the name.
      # The html_options have a special feature for creating javascript confirm alerts where if you pass :confirm => 'Are you sure?',
      # the link will be guarded with a JS popup asking that question. If the user accepts, the link is processed, otherwise not.
      #
      # Example:
      #   link_to "Delete this page", { :action => "destroy", :id => @page.id }, :confirm => "Are you sure?"
      def link_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
        html_options = (html_options || {}).stringify_keys
        convert_confirm_option_to_javascript!(html_options)
        if options.is_a?(String)
          content_tag "a", name || options, (html_options || {}).merge("href" => options)
        else
          content_tag(
            "a", name || url_for(options, *parameters_for_method_reference),
            (html_options || {}).merge("href" => url_for(options, *parameters_for_method_reference))
          )
        end
      end

      # Creates a link tag on the image residing at the +src+ using an URL created by the set of +options+. This takes the same options 
      # as url_for. For a list, see the url_for documentation in link:classes/ActionController/Base.html#M000079. 
      # It's also possible to pass a string instead of an options hash to get a link tag that just points without consideration. 
      # The <tt>html_options</tt> works jointly for the image and ahref tag by letting the following special values enter the options on
      # the image and the rest goes to the ahref:
      #
      # * <tt>:alt</tt> - If no alt text is given, the file name part of the +src+ is used (capitalized and without the extension)
      # * <tt>:size</tt> - Supplied as "XxY", so "30x45" becomes width="30" and height="45"
      # * <tt>:border</tt> - Draws a border around the link
      # * <tt>:align</tt> - Sets the alignment, no special features
      #
      # The +src+ can be supplied as a...
      # * full path, like "/my_images/image.gif"
      # * file name, like "rss.gif", that gets expanded to "/images/rss.gif"
      # * file name without extension, like "logo", that gets expanded to "/images/logo.png"
      #
      # Examples:
      #   link_image_to "logo", { :controller => "home" }, :alt => "Homepage", :size => "45x80"
      #   link_image_to "delete", { :action => "destroy" }, :size => "10x10", :confirm => "Are you sure?", "class" => "admin"
      #
      # NOTE: This tag is deprecated. Combine the link_to and image_tag yourself instead, like:
      #   link_to(image_tag("rss", :size => "30x45", :border => 0), "http://www.example.com")
      def link_image_to(src, options = {}, html_options = {}, *parameters_for_method_reference)
        image_options = { "src" => src.include?("/") ? src : "/images/#{src}" }
        image_options["src"] += ".png" unless image_options["src"].include?(".")

        html_options = html_options.stringify_keys
        if html_options["alt"]
          image_options["alt"] = html_options["alt"]
          html_options.delete "alt"
        else
          image_options["alt"] = src.split("/").last.split(".").first.capitalize
        end

        if html_options["size"]
          image_options["width"], image_options["height"] = html_options["size"].split("x")
          html_options.delete "size"
        end

        if html_options["border"]
          image_options["border"] = html_options["border"]
          html_options.delete "border"
        end

        if html_options["align"]
          image_options["align"] = html_options["align"]
          html_options.delete "align"
        end

        link_to(tag("img", image_options), options, html_options, *parameters_for_method_reference)
      end

      alias_method :link_to_image, :link_image_to # deprecated name

      # Creates a link tag of the given +name+ using an URL created by the set of +options+, unless the current
      # request uri is the same as the link's, in which case only the name is returned (or the
      # given block is yielded, if one exists). This is useful for creating link bars where you don't want to link
      # to the page currently being viewed.
      def link_to_unless_current(name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        link_to_unless current_page?(options), name, options, html_options, *parameters_for_method_reference, &block
      end

      # Create a link tag of the given +name+ using an URL created by the set of +options+, unless +condition+
      # is true, in which case only the name is returned (or the given block is yielded, if one exists). 
      def link_to_unless(condition, name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        if condition
          if block_given?
            block.arity <= 1 ? yield(name) : yield(name, options, html_options, *parameters_for_method_reference)
          else
            html_escape(name)
          end
        else
          link_to(name, options, html_options, *parameters_for_method_reference)
        end  
      end
      
      # Create a link tag of the given +name+ using an URL created by the set of +options+, if +condition+
      # is true, in which case only the name is returned (or the given block is yielded, if one exists). 
      def link_to_if(condition, name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        link_to_unless !condition, name, options, html_options, *parameters_for_method_reference, &block
      end

      # Creates a link tag for starting an email to the specified <tt>email_address</tt>, which is also used as the name of the
      # link unless +name+ is specified. Additional HTML options, such as class or id, can be passed in the <tt>html_options</tt> hash.
      #
      # You can also make it difficult for spiders to harvest email address by obfuscating them.
       # Examples:
      #   mail_to "me@domain.com", "My email", :encode => "javascript"  # =>
      #     <script type="text/javascript" language="javascript">eval(unescape('%64%6f%63%75%6d%65%6e%74%2e%77%72%69%74%65%28%27%3c%61%20%68%72%65%66%3d%22%6d%61%69%6c%74%6f%3a%6d%65%40%64%6f%6d%61%69%6e%2e%63%6f%6d%22%3e%4d%79%20%65%6d%61%69%6c%3c%2f%61%3e%27%29%3b'))</script>
      #
      #   mail_to "me@domain.com", "My email", :encode => "hex"  # =>
      #     <a href="mailto:%6d%65@%64%6f%6d%61%69%6e.%63%6f%6d">My email</a>
      def mail_to(email_address, name = nil, html_options = {})
        html_options = html_options.stringify_keys
        encode = html_options.delete("encode")
        string = ''
        if encode == 'javascript'
          tmp = "document.write('#{content_tag("a", name || email_address, html_options.merge({ "href" => "mailto:"+email_address.to_s }))}');"
          for i in 0...tmp.length
            string << sprintf("%%%x",tmp[i])
          end
          "<script type=\"text/javascript\" language=\"javascript\">eval(unescape('#{string}'))</script>"
        elsif encode == 'hex'
          for i in 0...email_address.length
            if email_address[i,1] =~ /\w/
              string << sprintf("%%%x",email_address[i])
            else
              string << email_address[i,1]
            end
          end
          content_tag "a", name || email_address, html_options.merge({ "href" => "mailto:#{string}" })
        else
          content_tag "a", name || email_address, html_options.merge({ "href" => "mailto:#{email_address}" })
        end
      end

      # Returns true if the current page uri is generated by the options passed (in url_for format).
      def current_page?(options)
        url_for(options) == @request.request_uri
      end

      private
        def convert_confirm_option_to_javascript!(html_options)
          if confirm = html_options.delete("confirm")
            html_options["onclick"] = "return confirm('#{confirm.gsub(/'/, '\\\\\'')}');"
          end
        end
    end
  end
end