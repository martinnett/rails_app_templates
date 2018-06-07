RAILS_REQUIREMENT = '~> 5.1.1'.freeze

# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

def apply_template!
  assert_minimum_rails_version

  remove_file 'README.rdoc'
  template 'templates/gitignore.tt', '.gitignore', force: true
  template 'templates/Gemfile.tt', 'Gemfile', force: true
  template 'templates/config.ru.tt', 'config.ru', force: true
  template 'templates/README.md.tt', 'README.md', force: true
  template 'templates/application.rb.tt', 'config/application.rb', force: true
  template 'templates/database.yml.tt', 'config/database.yml', force: true
  template 'templates/routes.rb.tt', 'config/routes.rb', force: true

  init_deploy

  template 'templates/high_voltage.rb.tt', 'config/initializers/high_voltage.rb', force: true
  template 'templates/api/api.rb.tt', "app/api/#{app_name}_api.rb", force: true
  template 'templates/api/base.rb.tt', 'app/api/v1/base.rb', force: true

  generate 'controller home index'

  after_bundle do
    say 'Stop spring if exsit'
    run 'spring stop'
    run 'rails db:drop'
    run 'rails db:setup'
    generate 'devise:install'
    template 'templates/envs/development.rb.tt', 'config/environments/development.rb', force: true
    template 'templates/envs/production.rb.tt', 'config/environments/production.rb', force: true
    generate 'devise User'
    generate 'settings:install'
    run 'rake db:migrate'
    template 'templates/application_controller.rb.tt', 'app/controllers/application_controller.rb', force: true

    git :init
    git add: '.'
    git commit: '-m "Init project successfully."'
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def init_deploy
  run 'cap install'
  template 'templates/Capfile.tt', 'Capfile', force: true
  template 'templates/deploy.rb.tt', 'config/deploy.rb', force: true
end

apply_template!
