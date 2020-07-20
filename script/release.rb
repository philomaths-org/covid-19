#!/usr/bin/env ruby
# creates a new release and tag
# In order to bundle and execute: ruby script/release.rb
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'tty-prompt'
  gem 'chris_lib', require: 'chris_lib/shell_methods'
end
include ShellMethods

prompt = TTY::Prompt.new
name = prompt.select 'Select pdf file name', %w(fii systems)
case name
when 'fii'
  system('cp ../covid_tracker/latex/free_infected/fii.pdf fii.pdf')
when 'systems'
  system('cp ../covid_tracker/latex/self_isolation/systems.pdf systems.pdf')
end
target = prompt.ask 'Enter target name (copy from \fancyhead minus pdf extension)'
system("cp #{name}.pdf #{target}.pdf" )
tag = prompt.ask 'Tag name, as shown in \fancyhead '
git_commit "add #{target}.pdf"
system("git tag #{tag} -a")
system("git push origin #{tag}")

BEGIN {
  def git_commit(msg)
    `git add .`
    `git status`
    system("git commit -m '#{msg}'")
  end
}

