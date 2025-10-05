# frozen_string_literal: true

# Utility functions for rake tasks
module TaskUtilities
  def barf(e, ctx)
    # no need to pass in $! ?
    STDERR.puts "#{ctx}: #{e.inspect}"
    STDERR.puts e.backtrace.select {|l| l.to_s[File.basename(__FILE__)]}
  end

  def progress_bar(total, force=false, objects='records')
    @progress = 0
    @total = total
    bar = nil
    if not system("[ -t 1 ]") or force
      require 'progress_bar'
      bar = ProgressBar.new(total, :bar, :counter, :percentage, :elapsed, :eta)
    end
    str = "About to process #{@total} #{objects}"
    if bar.nil?
      puts str
    else
      STDERR.puts str
    end
    bar
  end

  def update_progress(bar, msg='')
    if not bar.nil?
      bar.increment!
    else
      @progress += 1
      if msg.empty?
        STDERR.puts "Processing #{@progress} of #{@total}"
      else
        STDERR.puts "#{msg} – processing #{@progress} of #{@total}"
      end
    end
    true
  end
end