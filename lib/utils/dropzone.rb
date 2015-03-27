module TestChamber

  class Dropzone

    @asset_filepath = File.absolute_path(File.join('.', 'assets'))

    class << self

      # Attach an image to a Dropzone.js element on the current page
      # filename: the name string of the image file to attach
      # element_id: the DOM id of the Dropzone element
      # put_img_path: The API route to use to post the image to, this is declared in the Dropzone Backbone view
      # model_attribute: The name of the Backbone model attribute to assign the uploaded image path to, defaults
      #                   to the element_id
      def attach_image(filename, element_id: , put_img_path: , model_attribute: nil)
        model_attribute ||= element_id
        injected_file = inject_file filename, element_id, put_img_path

        page.execute_script 'window.Dashboard.router.pageView.model.'+
                               "attributes['#{model_attribute}']='#{injected_file}'"
      end

      # Attach a video to a Dropzone.js element on the current page
      # filename: the name string of the video file to attach
      # element_id: the DOM id of the Dropzone element
      # put_img_path: The API route to use to post the video to, this is declared in the Dropzone Backbone view
      # model_attribute: The name of the Backbone model attribute to assign the uploaded image path to, defaults
      #                   to the the string 'video_url'
      def attach_video(filename, element_id: , put_video_path: , model_attribute: 'video_url')
        injected_file = inject_file filename, element_id, put_video_path

        page.execute_script 'video = window.Dashboard.router.pageView.model.video;'
        page.execute_script "video.attributes['#{model_attribute}']='#{injected_file}'"
        page.execute_script '$(".video textarea[required]").attr("required", false)'+
                              '.attr("disabled", true);'
      end

      # Retrieve the form_id from the Backbone page view
      def form_id
        page.execute_script 'return window.Dashboard.router.pageView.formId'
      end

      # Retrieve the form_id from the page's Backbone model
      def cid
        page.execute_script 'return window.Dashboard.router.pageView.model.cid'
      end

      # Create a file object, pass to put_file and place resulting name in appropriate input field
      def inject_file(filename, element_id, api_route)
        filename = File.basename(filename)
        # Load and XHR the image file
        file = File.new(File.join(@asset_filepath, filename))
        if file.nil?
          raise "Invalid file or path #{filename}, default path is #{@asset_filepath}"
        end
        response = put_file api_route, file
        raise "Unable to put #{filename} to #{api_route} route" unless response

        input_filename = JSON.parse(response)["name"]
        page.execute_script "$('input[name=#{element_id}]')"+
                                ".val('#{input_filename}')"
        # Return path of uploaded file
        input_filename
      end

      def put_file(api_route, file)
        route = "#{TestChamber.target_url}/api/client/assets/#{api_route}?"
        route += "form_token=#{form_id}&cid=#{cid}"

        payload = {
            filename: File.basename(file),
            file: File.open(file)
        }

        TestChamber::Rest.authenticated_request :put, route, payload: payload
      end

    end

  end

end
