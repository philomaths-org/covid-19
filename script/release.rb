#!/usr/bin/env ruby
# creates a new release and tag
# Add new repository name to repos: structure should be /latex/name/name.pdf
# In order to bundle and execute: ruby script/release.rb
require 'bundler/inline'
require 'colorize'

gemfile do
  source 'https://rubygems.org'
  gem 'tty-prompt'
  gem 'chris_lib', require: 'chris_lib/shell_methods'
end
include ShellMethods
repos = %w(fii systems immunity)
prompt = TTY::Prompt.new
name = prompt.select 'Select pdf file name:', repos
leaf = leaf_key(name)
yes = prompt.yes? "Have you uploaded latest version of #{leaf} to S3}"
exit unless yes
copy_file_from_repo name, leaf
git_commit "add #{leaf}.pdf"
system('git push origin master')
system("open #{leaf}.pdf")
yes = prompt.yes? "Does url in header of pdf got to latest release?"
puts "You need to fix url".colorize(:red) unless yes
exit unless yes
tag =  prompt.ask 'Enter version, as found in resources section e.g. v2b:'
system("git tag -a #{name}-#{tag} -m 'New release'")
system("git push origin #{name}-#{tag}")
puts 'All Done'.colorize(:green)

BEGIN {
  def git_commit(msg)
    `git add .`
    system("git commit -m '#{msg}'")
  end

  def leaf_key
    {
      'fii': 'free_infected_individuals',
      'systems': 'social_distancing',
      'immunity': 'conditional_immunity'
    }
  end

  def copy_file_from_repo(name, leaf)
    system("cp ../covid_tracker/latex/#{name}/#{name}.pdf #{leaf}/#{leaf}.pdf")
  end
}

