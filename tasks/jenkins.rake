require 'jenkins_api_client'
require 'git'
require 'pp'

# Run the test_chamber automation on jenkins using the current_branch.
namespace :jenkins do
  JENKINS_SERVER = 'https://jenkins.tapjoy.net'
  JOB_NAME = 'test_chamber'
  
  def jenkins_api_params
    {
      :server_url => JENKINS_SERVER,
      :log_level  => ::Logger::INFO,
      :username   => ENV['JENKINS_USERNAME'],
      :password   => ENV['JENKINS_TOKEN']
    }.reject { |k,v| v.nil? }
  end
  
  def jenkins
    @jenkins ||= JenkinsApi::Client.new(jenkins_api_params)
  end

  def exit_with_message(msg)
    puts msg
    exit 1
  end
  
  def jenkins_credentials_explanation
    "In order to ask Jenkins to do something you need to have both JENKINS_USERNAME and JENKINS_TOKEN set in your environment.

JENKINS_USERNAME is the username you use to log into Jenkins.
JENKINS_TOKEN is your API key which can be found on the Jenkins server at

http://jenkins.tapjoy.net/user/<JENKINS_USERNAME>/configure

by clicking on the 'Show API Token' button.
"
  end
  
  def validate_environment
    unless ENV['JENKINS_USERNAME'] && ENV['JENKINS_TOKEN']
      exit_with_message "Environment variables JENKINS_USERNAME and JENKINS_TOKEN are required to start a Jenkins job and yours weren't set.

#{jenkins_credentials_explanation}"
    end
  end

  # Return the name of the current branch.
  # Make sure this test_chamber branch is clean and pushed up to GitHub.
  def current_branch
    return @current_branch if @current_branch

    project_root = File.absolute_path(File.join(File.dirname(__FILE__),'..'))
    git = Git.open(project_root)

    unless git.status.changed.empty?
      exit_with_message "There are currently uncommitted changes in your index.
Commit these changes and push the branch to GitHub so Jenkins can have access to the most recent test code."
    end
    
    @current_branch = git.current_branch
    current_sha = git.log.first.sha
    upstream_current_sha = begin
                             git.branch("origin/#{@current_branch}").gcommit.sha
                           rescue Git::GitExecuteError => e
                             exit_with_message "The current branch #{@current_branch} does not appear to have an upstream branch.
Be sure you have pushed it to github so that Jenkins can access it when running the tests.

#{e}
"
                           end
    if current_sha != upstream_current_sha
      exit_with_message "The current branch commit doesn't match the sha of the upstream branch on the origin remote.
This probably means you haven't pushed this branch up to GitHub.
Make sure you do that so that Jenkins can run the latest test code.

Branch:        #{current_branch}
Local commit:  #{current_sha}
Remote commit: #{upstream_current_sha}
"
    end
    @current_branch
  end

  desc "Run the current branch of test_chamber tests against test target specified by env var TARGET_URL.
You can specify a specific file or file pattern to run.

Example: rake 'jenkins:run_tests'                       # run all tests
         rake 'jenkins:run_tests[spec/features/app*]'   # run tests matching pattern
"
  task :run_tests, [:spec_files] do |t, args|
    validate_environment
    
    job_params = { :TARGET_URL => ENV['TARGET_URL'], :BRANCH => current_branch }
    job_params[:SPEC_FILE] = args[:spec_files] if args[:spec_files]
    
    puts "Launching jenkins test_chamber job:"
    pp job_params
    
    puts ""
    begin 
      job_number = jenkins.job.build(JOB_NAME, job_params, {'build_start_timeout' => 30, 'poll_interval' => 5})
    rescue Timeout::Error, JenkinsApi::Exceptions::Unauthorized => e
      if e.is_a?(Timeout::Error)
        puts "Your test run has been queued but hasn't started yet.

You can check on the progress at #{JENKINS_SERVER}/job/#{JOB_NAME}
Look for the build with #{ENV['TARGET_URL']} in the description"
      elsif e.is_a?(JenkinsApi::Exceptions::Unauthorized)
        exit_with_message "

Jenkins is sad because you provided credentials but they were invalid. Its possible that your API Token is incorrect

#{jenkins_credentials_explanation}
"
      end
    end
    puts ""

    puts "Your test run has been started.

You can check on the progress at #{JENKINS_SERVER}/job/#{JOB_NAME}/#{job_number}"
  end
end