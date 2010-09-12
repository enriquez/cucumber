Feature: Developer writes feature in Ruby
  In order to make features less frustrating to write
  As a developer
  I want to write features in Ruby

  Scenario: Feature in Ruby
    Given a standard Cucumber project directory structure
    And a file named "features/step_definitions/array_steps.rb" with:
      """
      Then /^it should have (\d+) items? in it$/ do |count|
        @array.size.should == count.to_i
      end
      """
    And a file named "features/modify_array_feature.rb" with:
      """
      class ModifyArrayFeature < RCucumber::Feature
        Feature "Modify Array"
        Narrative <<-DOC
          In order to test a feature written in Ruby
          I want to test an Array
        DOC

        Scenario 'Insert into Array' do
          Given 'I have a new instance of Array' do
            @array = Array.new
          end

          When 'I shovel :one into it' do
            @array << :one
          end

          Then 'it should have 1 item in it'
        end

        Scenario 'Delete from Array' do
          Given 'I have an Array with three items in it' do
            @array = Array.new
            @array << :one
            @array << :two
            @array << :three
          end

          When 'I delete the first items' do
            @array.delete_at(0)
          end

          Then 'it should have 2 items in it'
        end
      end
      """
    When I run cucumber --format pretty features/modify_array_feature.rb
    Then STDERR should be empty
    And the output should contain
      """
      Feature: Modify Array
        In order to test a feature written in Ruby
        I want to test an Array

        Scenario: Insert into Array            # features/modify_array_feature.rb:X
          Given I have a new instance of Array # features/modify_array_feature.rb:9
          When I shovel :one into it           # features/modify_array_feature.rb:13
          Then it should have 1 item in it     # features/step_definitions/array_steps.rb:1

        Scenario: Delete from Array                    # features/modify_array_feature.rb:X
          Given I have an Array with three items in it # features/modify_array_feature.rb:21
          When I delete the first items                # features/modify_array_feature.rb:28
          Then it should have 2 items in it            # features/step_definitions/array_steps.rb:1
      """

