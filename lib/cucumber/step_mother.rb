require 'cucumber/configuration'
require 'cucumber/constantize'
require 'cucumber/core_ext/instance_exec'
require 'cucumber/language_support/language_methods'
require 'cucumber/formatter/duration'
require 'cucumber/cli/options'
require 'cucumber/errors'
require 'cucumber/support_code'
require 'gherkin/rubify'
require 'timeout'
require 'cucumber/step_mother/user_interface'
require 'cucumber/step_mother/features_loader'

module Cucumber
  
  # This is the meaty part of Cucumber that ties everything together.
  class StepMother
    include Formatter::Duration
    include UserInterface
    
    class Results
      def step_visited(step) #:nodoc:
        steps << step unless steps.index(step)
      end
      
      def scenario_visited(scenario) #:nodoc:
        scenarios << scenario unless scenarios.index(scenario)
      end
      
      def steps(status = nil) #:nodoc:
        @steps ||= []
        if(status)
          @steps.select{|step| step.status == status}
        else
          @steps
        end
      end
      
      def scenarios(status = nil) #:nodoc:
        @scenarios ||= []
        if(status)
          @scenarios.select{|scenario| scenario.status == status}
        else
          @scenarios
        end
      end
    end

    def initialize(configuration = Configuration.default)
      @current_scenario = nil
      @configuration = parse_configuration(configuration)
      @support_code = SupportCode.new(self, @configuration.guess?)
      @results = Results.new
    end
    
    def step_visited(step) #:nodoc:
      @results.step_visited(step)
    end
    
    def scenarios(status = nil)
      @results.scenarios(status)
    end
    
    def steps(status = nil)
      @results.steps(status)
    end
    
    def load_plain_text_features(feature_files)
      loader = FeaturesLoader.new(feature_files, 
        @configuration.filters, 
        @configuration.tag_expression)
      loader.features
    end

    def load_code_files(step_def_files)
      @support_code.load_files!(step_def_files)
    end

    # Loads and registers programming language implementation.
    # Instances are cached, so calling with the same argument
    # twice will return the same instance.
    #
    def load_programming_language(ext)
      @support_code.load_programming_language!(ext)
    end

    def invoke(step_name, multiline_argument)
      @support_code.invoke(step_name, multiline_argument)
    end

    # Invokes a series of steps +steps_text+. Example:
    #
    #   invoke(%Q{
    #     Given I have 8 cukes in my belly
    #     Then I should not be thirsty
    #   })
    def invoke_steps(steps_text, i18n, file_colon_line)
      @support_code.invoke_steps(steps_text, i18n, file_colon_line)
    end
    
    # Returns a Cucumber::Ast::Table for +text_or_table+, which can either
    # be a String:
    #
    #   table(%{
    #     | account | description | amount |
    #     | INT-100 | Taxi        | 114    |
    #     | CUC-101 | Peeler      | 22     |
    #   })
    #
    # or a 2D Array:
    #
    #   table([
    #     %w{ account description amount },
    #     %w{ INT-100 Taxi        114    },
    #     %w{ CUC-101 Peeler      22     }
    #   ])
    #
    def table(text_or_table, file=nil, line_offset=0)
      if Array === text_or_table
        Ast::Table.new(text_or_table)
      else
        Ast::Table.parse(text_or_table, file, line_offset)
      end
    end

    # Returns a regular String for +string_with_triple_quotes+. Example:
    #
    #   """
    #    hello
    #   world
    #   """
    #
    # Is retured as: " hello\nworld"
    #
    def py_string(string_with_triple_quotes, file=nil, line_offset=0)
      Ast::PyString.parse(string_with_triple_quotes)
    end

    def step_match(step_name, name_to_report=nil) #:nodoc:
      @support_code.step_match(step_name, name_to_report)
    end

    def unmatched_step_definitions
      @support_code.unmatched_step_definitions
    end

    def snippet_text(step_keyword, step_name, multiline_arg_class) #:nodoc:
      @support_code.snippet_text(step_keyword, step_name, multiline_arg_class)
    end

    def with_hooks(scenario, skip_hooks=false)
      around(scenario, skip_hooks) do
        before_and_after(scenario, skip_hooks) do
          yield scenario
        end
      end
    end

    def around(scenario, skip_hooks=false, &block) #:nodoc:
      if skip_hooks
        yield
        return
      end
      
      @support_code.around(scenario, block)
    end

    def before_and_after(scenario, skip_hooks=false) #:nodoc:
      before(scenario) unless skip_hooks
      yield scenario
      after(scenario) unless skip_hooks
      @results.scenario_visited(scenario)
    end

    def before(scenario) #:nodoc:
      return if @configuration.dry_run? || @current_scenario
      @current_scenario = scenario
      @support_code.fire_hook(:before, scenario)
    end
    
    def after(scenario) #:nodoc:
      @current_scenario = nil
      return if @configuration.dry_run?
      @support_code.fire_hook(:after, scenario)
    end
    
    def after_step #:nodoc:
      return if @configuration.dry_run?
      @support_code.fire_hook(:execute_after_step, @current_scenario)
    end
    
    def after_configuration(configuration) #:nodoc
      @support_code.fire_hook(:after_configuration, configuration)
    end
    
    def unknown_programming_language?
      @support_code.unknown_programming_language?
    end

  private
  
    def log
      Cucumber.logger
    end
    
    def parse_configuration(configuration_argument)
      case configuration_argument
      when Hash
        Configuration.new(configuration_argument)
      when Configuration, Cucumber::Cli::Configuration
        configuration_argument
      else
        raise(ArgumentError, "Unknown configuration: #{configuration_argument.inspect}")
      end
    end
  end
end
