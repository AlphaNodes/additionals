$VERBOSE = nil

unless ENV['SKIP_COVERAGE']
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter[SimpleCov::Formatter::HTMLFormatter,
                                                              SimpleCov::Formatter::RcovFormatter]

  SimpleCov.start :rails do
    add_filter 'init.rb'
    root File.expand_path(File.dirname(__FILE__) + '/..')
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Additionals helper class for tests
module Additionals
  class ControllerTest < ActionController::TestCase
    # can be removed if Redmine 3.4 and higher is supported only
    def process(action, http_method = 'GET', *args)
      parameters, _session, _flash = *args
      if args.size == 1 && parameters[:xhr] == true
        xhr http_method.downcase.to_sym, action, parameters.except(:xhr)
      elsif parameters && (parameters.key?(:params) || parameters.key?(:session) || parameters.key?(:flash))
        super action, http_method, parameters[:params], parameters[:session], parameters[:flash]
      else
        super
      end
    end
  end

  class TestCase
    include ActionDispatch::TestProcess
    def self.plugin_fixtures(plugin, *fixture_names)
      plugin_fixture_path = "#{Redmine::Plugin.find(plugin).directory}/test/fixtures"
      if fixture_names.first == :all
        fixture_names = Dir["#{plugin_fixture_path}/**/*.{yml}"]
        fixture_names.map! { |f| f[(plugin_fixture_path.size + 1)..-5] }
      else
        fixture_names = fixture_names.flatten.map(&:to_s)
      end

      ActiveRecord::Fixtures.create_fixtures(plugin_fixture_path, fixture_names)
    end

    def uploaded_test_file(name, mime)
      ActionController::TestUploadedFile.new(ActiveSupport::TestCase.fixture_path + "/files/#{name}", mime, true)
    end

    def self.arrays_equal?(value1, value2)
      (value1 - value2) - (value2 - value1) == []
    end

    def self.create_fixtures(fixtures_directory, table_names, _class_names = {})
      ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, _class_names = {})
    end

    def self.prepare
      Role.where(id: [1, 2]).each do |r|
        r.permissions << :view_issues
        r.save
      end

      Project.where(id: [1, 2]).each do |project|
        EnabledModule.create(project: project, name: 'issue_tracking')
      end
    end
  end
end
