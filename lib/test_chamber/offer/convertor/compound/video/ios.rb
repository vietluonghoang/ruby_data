module TestChamber::Convertor
  module Compound
    module IOS
      class Video < TestChamber::Convertor::Compound::Base

        VIDEO_ENDED_FLAG = 'test-chamber-video-ended'

        def do_conversion!(*args)
          # wait for the video to be displayed
          Util.wait_for(10) do
            page.first(:tag, 'video')
          end

          # setup the video ended event listener
          page.execute_script(video_conversion_script)

          # wait for the listener to add the flag to the dom
          Util.wait_for(60) do
            page.first(:class, VIDEO_ENDED_FLAG)
          end
        end

        private

        def video_conversion_script
          get_video_element = "var video = document.getElementsByTagName('video')[#{@module_ordinal}];"
          add_css_flag =  "db = document.body; db.className = db.className ? db.className + ' #{VIDEO_ENDED_FLAG}' : '#{VIDEO_ENDED_FLAG}';"
          register_on_ended = "video.addEventListener('ended', function() { #{add_css_flag} });" 

          get_video_element + ' ' + register_on_ended
        end
      end
    end
  end
end
