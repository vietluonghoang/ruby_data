module TestChamber

  # Convenience wrapper for accepting confirmation dialogs.
  # Found this here http://stackoverflow.com/questions/2458632/how-to-test-a-confirm-dialog-with-cucumber
  # For selenium you can use https://github.com/ExtractMethod/prickle but for phantomjs it doesn't work.
  module ConfirmationDialog
    def confirmation_dialog(accept=true)
      page.execute_script "window.original_confirm_function = window.confirm"
      page.execute_script "window.confirmMsg = null"
      page.execute_script "window.confirm = function(msg) { window.confirmMsg = msg; return #{!!accept}; }"
      yield
    ensure
      page.execute_script "window.confirm = window.original_confirm_function"
    end

    def get_confirm_text
      page.evaluate_script "window.confirmMsg"
    end
  end
end