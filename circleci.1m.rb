#!/usr/bin/ruby
#
# <bitbar.title>CircleCI monitor</bitbar.title>
# <bitbar.version>v0.1</bitbar.version>
# <bitbar.author>Raphael H. Doehring</bitbar.author>
# <bitbar.author.github>wrtsprt</bitbar.author.github>
# <bitbar.desc>Plugin monitoring CircleCI latest builds</bitbar.desc>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl></bitbar.abouturl>
#
#
# This is a small bitbar plugin to monitor the branches on Circle CI. It's pretty much a rip off of
# https://getbitbar.com/plugins/Dev/CircleCI/circleci-check.5m.py
#
# INSTALLATION:
#
# Add your Circle CI token to the keychain:
# `security add-generic-password -a circle-ci-user -s circle-ci-alfred-token -w YOURTOKENHERE`

require 'net/http'
require 'json'
require 'open-uri'



CIRCLE_CI_BASE_URL = 'https://circleci.com/api/v1.1'

COLORS = {
  'running' => '#61D3E5',
  'success' => '#39C988',
  'fixed' => '#39C988',
  'failed' =>'#EF5B58',
  'timedout' => '#F3BA61',
  'canceled' => '#898989',
  'scheduled' =>'#AC7DD3',
  'no_tests' => 'black',
}

STATUS = {
  'running' => '↺',
  'failed' => '🛑',
  'success' => '✅'
}

$all_green = true
$any_running = false

def i_can_haz_internet?
  begin
    true if open('https://circleci.com')
  rescue
    false
  end
end

def api_token
  output = `security find-generic-password -l circle-ci-alfred-token -w`
  if output =~ /The specified item could not be found in the keychain/
    raise "api token not setup in keychain"
  else
    output.chomp
  end
end

# https://circleci.com/docs/api/v1-reference/
def recent_builds
  url = CIRCLE_CI_BASE_URL + '/recent-builds' + '?circle-token=' + api_token

  uri = URI(url)
  res = Net::HTTP.get_response(uri)

  raise "unexpected response code: #{res.code}" unless res.code == '200'
#   puts res.code       # => '200'

  res.body
end

def extract_recent_builds_info(recent_builds)
  recent_builds.map do |build|
    [build['branch'], build['status']]
  end
end

def filtered_builds(builds)
  after_exclude = builds.reject do |build|
    build['status'] == 'canceled'
  end

  after_exclude.select do |build|
    build['branch'] =~ /^raphael-/ || build['branch'] =~ /^master$/
  end
end

def collect_by_branch(buildz)
  by_branch = {}

  buildz.each do |build|
    branch = build['branch']
    unless by_branch.has_key?(branch)
      by_branch[branch] = {'builds' => []}
      by_branch[branch]['status'] = build['status']
      $all_green = false if build['status'] != 'success'
      $any_running = true if build['status'] == 'running'
    end
    by_branch[branch]['builds'] << build
  end

  by_branch
end

def format_for_bitbar(buildz)
  # "Show Graphs | color=#123def href=http://example.com/graph?foo=bar"
  buildz.each do |build|
    puts "#{build['branch']} (#{build['status']}) | color=#{COLORS[build['status']]} href=#{build['build_url']}"
  end

end

def format_by_branch(buildz_by_branch)
  buildz_by_branch.each do |branch, branch_info|
    builds = branch_info['builds']
    puts "---"
    puts "#{branch} | size=14 color=black"
    # "Show Graphs | color=#123def href=http://example.com/graph?foo=bar"
    builds.each do |build|
      puts " - #{build['branch']} (#{build['status']}) | size=12 color=#{COLORS[build['status']]} href=#{build['build_url']}"
    end
  end

end

the_recent_builds = recent_builds
recent_builds_hash = JSON.parse(the_recent_builds)

filtered_builds = filtered_builds recent_builds_hash

builds_by_branch = collect_by_branch filtered_builds

# extract_recent_builds_info recent_builds_hash
# puts 'Circle'
if $any_running
  puts STATUS['running']
elsif $all_green
  puts STATUS['success']
else
  puts STATUS['failed']
end
puts '---'

# format_for_bitbar filtered_builds
format_by_branch builds_by_branch

if i_can_haz_internet?
  display_recent_builds
else
  puts "⏳"
end
