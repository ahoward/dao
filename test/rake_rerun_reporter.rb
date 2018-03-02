require "minitest/reporters"

module Minitest
  module Reporters
    class RakeRerunReporter < Minitest::Reporters::DefaultReporter

      def initialize(options = {})
        @rerun_user_prefix=options.fetch(:rerun_prefix, "")
        super
      end

      def report
        super
      
        puts
      
        unless @fast_fail
          #print rerun commands
          failed_or_error_tests=(tests.select {|t| t.failure && !t.skipped? })

          unless failed_or_error_tests.empty?
            puts red("You can rerun failed/error test by commands (you can add rerun prefix with 'rerun_prefix' option):")

            failed_or_error_tests.each do |test|
              print_rerun_command(test)
            end
          end
        end
        
        #summary for all suite again
        puts
        print colored_for(suite_result, result_line)
        puts
        
      end  

      private

        def print_rerun_command(test)
          message = rerun_message_for(test)
          unless message.nil? || message.strip == ''
            puts
            puts colored_for(result(test), message)
          end
        end

        def rerun_message_for(test)
          file_path=location(test.failure).gsub(/(\:\d*)\z/,"")
          msg="#{@rerun_user_prefix} rake test TEST=#{file_path} TESTOPTS=\"--name=#{test.name} -v\""
          if test.skipped?
            "Skipped: \n#{msg}"
          elsif test.error?
            "Error:\n#{msg}"
          else
            "Failure:\n#{msg}"
          end
        end
        
        def location(exception)
          last_before_assertion = ''

          exception.backtrace.reverse_each do |ss|
            break if ss =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
            last_before_assertion = ss
            break if ss=~ /_test.rb\:/
          end

          last_before_assertion.sub(/:in .*$/, '')
        end  

    end
  end
end

