require_relative 'test_helper'

module CLI
  class TestModel < Test::Unit::TestCase

    def test_find

      output = capture_stdout do
        count = AmplifyOpenSearchBackfill::CLI.new.
          invoke(:status, [], {
            'api-name': 'factory',
            'model-name' => 'widget'
          })
      end
      puts "OUTPUT: #{output}"
      # assert_includes output, 'Something'

    end

  end
end
