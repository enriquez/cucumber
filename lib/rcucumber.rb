require 'cucumber/ast/feature'

module RCucumber
  class Feature
    class << self; attr_accessor :feature, :narrative, :scenarios, :step_definitions end
    @scenarios = []
    @step_definitions = {}

    def self.inherited(subclass)
      subclass.instance_variable_set("@scenarios", @scenarios)
      subclass.instance_variable_set("@feature", @feature)
      subclass.instance_variable_set("@narrative", @narrative)
      subclass.instance_variable_set("@step_definitions", @step_definitions)
    end

    def self.Feature(name)
      @feature = name
    end

    def self.Narrative(narrative)
      @narrative = narrative
    end

    def self.Scenario(name)
      @steps_for_scenario = []
      yield
      steps = @steps_for_scenario.dup

      scenario = Cucumber::Ast::Scenario.new(
        nil,
        Cucumber::Ast::Comment.new(nil),
        Cucumber::Ast::Tags.new(nil, []),
        'X',
        "Scenario",
        name,
        steps
      )

      @scenarios << scenario
    end

    def self.Given(name, &block)
      Step("Given ", name, &block)
    end
    def self.When(name, &block)
      Step("When ", name, &block)
    end
    def self.Then(name, &block)
      Step("Then ", name, &block)
    end

    private
    def self.Step(keyword, name, &block)
      @step_definitions[name] = block if block_given?
      step = Cucumber::Ast::Step.new(nil, keyword, name)
      @steps_for_scenario << step
    end
  end

  class FeatureFile
    def initialize(file)
      @file = file
    end

    def parse(options, tag_counts)
      original_constants = Class.constants
      require File.expand_path(@file)
      klass_name = (Class.constants - original_constants).first
      klass = Class.const_get(klass_name)

      readme = klass::feature << "\n"
      klass::narrative.each_line { |l| readme << l.lstrip }

      feature = Cucumber::Ast::Feature.new(
        nil,
        Cucumber::Ast::Comment.new(nil),
        Cucumber::Ast::Tags.new(nil, []),
        "Feature",
        readme,
        klass.scenarios
      )

      feature.file = @file
      feature.language = Gherkin::I18n.new('en')
      feature
    end
  end
end
