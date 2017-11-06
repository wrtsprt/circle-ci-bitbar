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


CIRCLE_CI_LOGO_GREEN = 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABGdBTUEAALGPC/xhBQAAAt9JREFUOBGVVU1MU0EQntltsYohUhDCRduCxsSD8lMaNUYPxkTl4FUhGpNi24uoFw960MQYE6MJB6EP0agRTbhw8eKBxIMcHhY4GBMi5SdB4CIoKlFo366zwL6+Fiq6yWb+vpmdNzO7D2GdVZswtswJ0SglnkSEGimhDBB+E3QKAfoYQE8yGHmDiDLXneyZJSmCPxG/CALvAEhvxrKWI8cBxqBlNBjrc1rtgCpY4L3xnGiTE/A3npzTlGXLWH20TeMo+5UVSBit/xNMedH3uoSUD/2mEV4NQ5WhFTDjVwXI+1rppJTBPMkjtMvowB1Om+YJk+LoCiWD4SHm//CoXIK8pY0ZilOc8TN1QW/JeH00SHsn9xSWk3Mb5DSDDnJbMn1P+aLfbL9Oqd/OBFpWT7g8/HByX/PnbP2KFDCNswJEV67Njbya0Wknsg1oMYSwDnZgsnsz1fdUZX/HQY0bC0VeUi6vtKypJa3TzMvwuMu9qUxvxrGEutarQFUjL4pmZuYGhSVeE7jPb8Y7tTO6eLvmNZWAdfbYaKWTBvqNmJDCHgll8xSAf7g6NrH3Y/fWhYXZeWq1PSnU4qGM4Iz0D/xiwRL50j3KWa7dCaPUQr5N6zlP/fq0PzalZFZc2CW+/rwEUu5RMgI+Hq6OTigevv2ooeyyAqLEaZayZI+VTo3ovbSEkwGzo0H5JHc1fa+o8NYwzho48kPjoag9wJbAywrjXAgygT4zfo1m/q7TQOdOc+4+MlobTmbpVwW6CFG6CGuaosYGqwafbLdSi0maxSKnMw3wF4nyhq/U8+yt/4J6aaByoLNKWOmbNMiNTqziCd9Lw39suQa+foPqJFpzQavAFNVqgm5TKcnF+TD66tlF9ZnGAwBxZT2HjXQIrHk8FFmeUTsgfQbS3D2lTM5tFEDbyTn/80U1kNTF88hYhJoyq53yUQqmHtijzrdQYe0MnY55fwESpmmU39FE5/0F/AECsB5MVOAz8wAAAABJRU5ErkJggg=='
CIRCLE_CI_LOGO_RED = 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABGdBTUEAALGPC/xhBQAAAnFJREFUOBGVVb1rU1EUP+e1b4iEoiZNN0VwcDUogiLpIAW1g6tWdKlftO/F2MHBDk+QUpDapm10UVChOnZxcehmNrV/QDsEtJnyhroYmqTX333m3ndzYzReuDnfv3vuOSf3Mf1hiSA4QGE4QUJcgjkLmiHmOugOaJkcZ52KxY/MLOxwNhVCCCbfv43AOezDpq2LZ/4CXZ5XV8umTQNGYJ73FkDXTYe/8szNNuhz5ecohjyv+F9gMlCIQeySmJqaVDhRhlA8gGJBKS26i7ptQZdB8BHLpsQG6nqGV1Y2HZHPj0D7WFkMugP+KuVyKdTpNPZRSiRGAC6vZzfDpf39pzKWxfT0I5z8RArGquDE8zjxu6HTLGKuIWZNKxTjuidlDS8quU1bNDAwqcBEoZAQnndZ+P5Z5Yds3yHT90rWtNm84lA6PYZsMnonkyleXt6QTgAaokbjK67zgVqtMjJ7qYOZX2g+Zk7psYl1MQfAewDTIxFZXPcYLy1VMPxJqtV2cfV4Upg3YyHG6Y8LQwdgXQkNipmZNLI4aKD85MVF2WG51lArH4EnIon5lcwu4oXIgtqAVYfq9XXa29sy9jfM5bgMQmN+kOtmUd9xNOocmqEHGIfcj4A7fz4zgh9CN9+hZ64CKIdMtzv0bQHNuQvA7qZgbBiFH4ZxG3vICq4hs1lKpd5wENSlDSN0HDcJwE5I2VobXCpdiGoAUB91LFoOSmygjhUcmIbikFJaVP/1dFFxjWcIKliO/Yq3kF00ozGgHAHPew3QG/2iIPPez5d8fdHFm3C6gx3+E/T3AzuKmI7B1xmaAD0/AURV+H1Cs3p+An4BNJz8moZTB6UAAAAASUVORK5CYII='
CIRCLE_CI_LOGO_PLAY = 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAABGdBTUEAALGPC/xhBQAAApVJREFUOBGVlUtoE1EUhp3JAxKCUVtTkoVScC1Y8iBIIIIIGlO71Yhu1HajFcGVLhTEjbhQ8AUuVFCXVZCCYCEL0+YlBbd1UVFDFrooBJKQmPidMXe4jInVCzfn9Z//nnPPZMbYMmRls1l/vV7P9fv9I4SnDMMIobeQ37AL7IVyufwWu+9MN3QHSUYikTiHvMneocecOmQfXC7XfLFYlAPsZRMKWTwef4Y8aUc3USDtApmvVCr3FdQmjEajd3GeV4H/kaZpnuUKHkuORUhll3q93u0RJBtUskblIeK7RmA6+BPVanXV5M4mILvuBEIiAzg+OTk5RksxwLu9Xu8EfmnPOQwP/lvCIfd2BcIbYqhFcJ02UqVS6avy6ZKcE+Q8132ik7fPJHBYD+D8iX1GkXG3lyGY1THc1wvsl7pPdHJnzHA4fMjn84XUDgaD0uKSAgM6wKEPY7HYvXQ67VZ+OnigdCXBRe0pK6dTQrTIQKwuIH/ndrunV1ZWmpAHGo3GBnhT5RBftQ3lHCL1Q/dS2XbBNJtNydVjVqqbk8bb7fY2y/r906QCmbBaaqIfPR7PdKFQqEmAaqZEKJBIOqmZlL3Q6XTWtP2FIRzVgNLW60AgsH95efmz8ne73YtKV5Lqq2zzjXIMpMHlPkomk3vEzmQyOZ7BmXw+31A4DpxDP6ZsJanwlZFKpXa2Wq1PGFtVYCC/c9hVv9//FLKW+OQQKrsGNufAyhUs8XQctO6ASV4AdMcJGtgdwOvo42CsgQzB2X89lwRrtVopEokEUZNDwIIZY/uGxCwXncxR3aIY9pQ43aDSJ/hOSeBfFpX/8fqyn0OCfS7/NHKW/WMzQjDygk1Tmf0ulBy7Qp3gL58AeQbfs0d+An4BFEsa0Ka0vXAAAAAASUVORK5CYII='

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


def display_recent_builds
  the_recent_builds = recent_builds
  recent_builds_hash = JSON.parse(the_recent_builds)

  filtered_builds = filtered_builds recent_builds_hash

  builds_by_branch = collect_by_branch filtered_builds

  # extract_recent_builds_info recent_builds_hash
  if $any_running
    puts "| image=#{CIRCLE_CI_LOGO_PLAY}"
  elsif $all_green
    puts "| image=#{CIRCLE_CI_LOGO_GREEN}"
  else
    puts "| image=#{CIRCLE_CI_LOGO_RED}"
  end
  puts '---'

  # format_for_bitbar filtered_builds
  format_by_branch builds_by_branch
end

if i_can_haz_internet?
  display_recent_builds
else
  puts "⏳"
end
