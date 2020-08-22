#!/usr/bin/env ruby
# creates a new release and tag
# Add new repository name to repos: structure should be /latex/name/name.pdf
# In order to bundle and execute: ruby script/release.rb
require 'bundler/inline'
require 'dotenv'
Dotenv.load
require 'colorize'
gemfile do
  source 'https://rubygems.org'
  gem 'tty-prompt'
  gem 'chris_lib', require: 'chris_lib/shell_methods'
  gem 'dotenv'
  gem 'aws-sdk-s3'
  gem 'pry'
end

include ShellMethods

repos = %w(fii systems immunity)
prompt = TTY::Prompt.new
s3 = new_s3
name = prompt.select 'Select pdf file name:', repos
leaf = leaf_key(name)
copy_file_from_repo name, leaf
upload_pdf s3, name, leaf
git_commit "add #{leaf}.pdf"
system('git push origin master')
system("open https://www.philomaths.org/papers/#{leaf}.pdf")
yes = prompt.yes? "Does url in header of pdf got to latest release?"
puts "You need to fix url".colorize(:red) unless yes
exit unless yes
tag =  prompt.ask 'Enter version, as found in the header e.g. TN1-v17'
system("git tag -a #{name}-#{tag} -m 'New release'")
system("git push origin #{name}-#{tag}")
puts 'All Done'.colorize(:green)

BEGIN {

  def new_s3
    access_key_id = ENV['ACCESS_KEY_ID']
    secret_access_key = ENV['SECRET_ACCESS_KEY']
    credentials = Aws::Credentials.new access_key_id, secret_access_key
    Aws::S3::Resource.new(region: 'us-east-1', credentials: credentials)
  end

  def upload_pdf(s3, name, leaf)
    obj = s3.bucket('covid-tracker-us-east').object("papers/#{leaf}.pdf")
    obj.upload_file "#{leaf}/#{leaf}.pdf"
  end

  def git_commit(msg)
    `git add .`
    system("git commit -m '#{msg}'")
  end

  def leaf_key(name)
    {
      'fii': 'free_infected_individuals',
      'systems': 'social_distancing',
      'immunity': 'conditional_immunity'
    }[name.to_sym]
  end

  def copy_file_from_repo(name, leaf)
    system("cp ../covid_tracker/latex/#{name}/#{name}.pdf #{leaf}/#{leaf}.pdf")
  end
}

