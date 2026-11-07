#!/usr/bin/env ruby

# List all keys stored in memcache. 
# Credit to Graham King at http://www.darkcoding.net/software/memcached-list-all-keys/ for the original article on how to get the data from memcache in the first place.

require 'socket'
require 'timeout'

def memcache_command(socket, command)
  socket.write("#{command}\r\n")
  response = +""
  Timeout.timeout(3) do
    loop do
      line = socket.gets
      raise EOFError, "Memcached closed the connection" unless line
      break if line.strip == "END"
      response << line
    end
  end
  response
end

headings = %w(id expires bytes cache_key)
rows = []

localhost = Timeout.timeout(3) { TCPSocket.new("localhost", 11211) }
matches = memcache_command(localhost, "stats items").scan(/STAT items:(\d+):number (\d+)/)

slabs = matches.inject([]) { |items, item| items << Hash[*['id','items'].zip(item).flatten]; items }

longest_key_len = 0
slabs.each do |slab|
  c = memcache_command(localhost, "stats cachedump #{slab['id']} #{slab['items']}")
    matches = c.scan(/^ITEM (.+?) \[(\d+) b; (\d+) s\]$/).each do |key_data|
      cache_key, bytes, expires_time = key_data
      rows << [slab['id'], Time.at(expires_time.to_i), bytes, cache_key]
      longest_key_len = [longest_key_len,cache_key.length].max
    end
end

row_format = %Q(|%8s | %28s | %12s | %-#{longest_key_len}s |)
puts row_format%headings
rows.each{|row| puts row_format%row}

localhost.close
