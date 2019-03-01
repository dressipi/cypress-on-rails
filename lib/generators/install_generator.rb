module Cypress
  class InstallGenerator < Rails::Generators::Base
    def install
      empty_directory "spec/cypress"
      empty_directory "spec/cypress/integrations"
      empty_directory "spec/cypress/scenarios"
      empty_directory "spec/cypress/support"

      replace = [
        "# when running the cypress UI, allow reloading of classes",
        "config.cache_classes = (defined?(Cypress) ? Cypress.configuration.cache_classes : true)"
      ]
      gsub_file 'config/environments/test.rb', 'config.cache_classes = true', replace.join("\n")

      create_file "spec/cypress/cypress_helper.rb", <<-EOF
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)

Cypress.configure do |c|
  # change this to nil, if you are not using RSpec Mocks
  c.test_framework = :rspec

  # change this to nil, if you are not using DatabaseCleaner
  c.db_resetter = :database_cleaner

  c.before do
    # this is called when you call cy.setupScenario
    # use it to reset your application state
  end

  # add a module to your run context
  # c.include MyModule
end
EOF

    create_file "spec/cypress/integrations/simple_spec.js", <<-FILE
describe('My First Test', function() {
  it('visit root', function() {
    // This calls to the backend to prepare the application state
    // see the scenarios directory
    cy.setupScenario('basic')

    // The application under test is available at SERVER_PORT
    cy.visit('http://localhost:'+Cypress.env("SERVER_PORT"))
  })
})
FILE

    create_file "spec/cypress/scenarios/basic.rb", <<-FILE
scenario :basic do
  # You can setup your Rails state here
  # MyModel.create name: 'something'
end
FILE

    create_file "spec/cypress/support/setup.js", <<-FILE
// cypress-on-rails: dont remove these command
Cypress.Commands.add('setupScenario', function(name) {
  Cypress.log({ message: name })
  cy.request('POST', 'http://localhost:' + Cypress.env("SERVER_PORT") + "/__cypress__/scenario", JSON.stringify({ scenario: name }))
});

Cypress.Commands.add('setupRails', function () {
  cy.request('POST', 'http://localhost:' + Cypress.env("SERVER_PORT") + "/__cypress__/setup")
});

Cypress.Commands.add('rails', function(code) {
  cy.request('POST', 'http://localhost:' + Cypress.env("SERVER_PORT") + '/__cypress__/eval', JSON.stringify({ code: code }))
})
// cypress-on-rails: end

// The next setup is optional, but if you remove it you will have to manually reset the database
beforeEach(() => { cy.setupRails() });
FILE
    end
  end
end