# == Zotero Web API v3 Sync Check
#
# Script entry point: loads the Zotero client library (lib/zotero/client.rb,
# side-effect free on load) and runs the live sync.
#
# == Usage
#   bin/rails runner lib/zotero.rb

require_relative 'zotero/client'

Zotero.sync_report
