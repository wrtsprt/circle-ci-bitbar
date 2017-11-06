# circle-ci-bitbar

BitBar plugin to monitor CircleCI status. Written in ruby.

The plugin hits the `/recent-builds` endpoint (30 most recent builds), then filters according to the rules (see Configuration)
and displays the result as dropdown menu. Menubar icon is red if any of the branches is red, running if there's a current build running, 
green otherwise. 

# Installation

1. Get your API token here: `https://circleci.com/account/api`
2. Add it to the keychain: `security add-generic-password -a circle-ci-user -s circle-ci-alfred-token -w YOURTOKENHERE`
3. Copy circleci.1m.rb into your BitBar Plugins directoy or clone and link

# Configuration

At line `77` you can configure which branches to filter.


