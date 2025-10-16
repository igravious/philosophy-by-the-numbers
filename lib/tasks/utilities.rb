# frozen_string_literal: true

# Utility functions for rake tasks
module TaskUtilities
  # == Error Logging Utility
  #
  # Logs exceptions with context information to STDERR for debugging rake task failures.
  #
  # @param e [Exception] The exception object to log
  # @param ctx [String] Context string describing where the error occurred
  # @return [nil] Always returns nil
  #
  # == What it does:
  # 1. Prints context and exception inspection to STDERR
  # 2. Filters backtrace to show only relevant lines (excluding this utility file)
  # 3. Provides clean error output for rake task debugging
  #
  # == Examples:
  #   barf(e, "Failed to process philosopher")  # => nil
  #   # Output: Failed to process philosopher: #<RuntimeError: Invalid data>
  #   #         /path/to/calling/file.rb:42:in `method_name'
  #
  # == Used by:
  # - Rake tasks that need structured error logging
  # - Long-running batch operations for failure tracking
  #
  # == Notes:
  # - Designed for rake task environments where STDERR output is appropriate
  # - Backtrace filtering prevents clutter from utility method internals
  def barf(e, ctx)
    # no need to pass in $! ?
    STDERR.puts "#{ctx}: #{e.inspect}"
    STDERR.puts e.backtrace.select {|l| l.to_s[File.basename(__FILE__)]}
  end

  # == Progress Bar Setup
  #
  # Creates a progress bar for tracking long-running rake task operations.
  # Automatically detects terminal capabilities and falls back to text output.
  #
  # @param total [Integer] Total number of items to process
  # @param force [Boolean] Force progress bar creation even without TTY (default: false)
  # @param objects [String] Name of objects being processed (default: 'records')
  # @param msg [String] Additional message to display (default: '')
  # @return [ProgressBar, nil] Progress bar instance or nil if not available
  #
  # == What it does:
  # 1. Detects if running in a terminal environment
  # 2. Creates ProgressBar instance with counter, percentage, elapsed time, and ETA
  # 3. Falls back to simple text output when progress bar unavailable
  # 4. Prints initial status message (skipped in test environment)
  # 5. Initializes instance variables for fallback progress tracking
  #
  # == Examples:
  #   bar = progress_bar(1000, false, 'philosophers')
  #   # => ProgressBar instance or nil
  #
  #   bar = progress_bar(50, true, 'works', 'with validation')
  #   # => Forces progress bar creation with custom message
  #
  # == Used by:
  # - shadow:work:populate task for Wikidata processing
  # - delta_phases:* tasks for convergence analysis
  # - Any rake task processing large datasets
  #
  # == Performance Notes:
  # - Progress bar creation requires 'progress_bar' gem
  # - Text fallback has minimal performance impact
  # - Automatic TTY detection prevents issues in non-interactive environments
  #
  # == Notes:
  # - Skips progress messages entirely in test environment (Rails.env.test?)
  # - Instance variables @progress and @total used by update_progress fallback
  def progress_bar(total, force=false, objects='records', msg='')
    @progress = 0
    @total = total
    bar = nil
    if not system("[ -t 1 ]") or force
      require 'progress_bar'
      bar = ProgressBar.new(total, :bar, :counter, :percentage, :elapsed, :eta)
    end
    # Only show progress messages in development/production, not in test
    unless Rails.env.test?
      str = "About to process #{@total} #{objects} #{msg}"
      if bar.nil?
        puts str
      else
        STDERR.puts str
      end
    end
    bar
  end

  # == Progress Update
  #
  # Updates progress bar or prints progress message for long-running operations.
  #
  # @param bar [ProgressBar, nil] Progress bar instance from progress_bar() or nil
  # @param msg [String] Optional custom message to display (default: '')
  # @return [true] Always returns true
  #
  # == What it does:
  # 1. Increments progress bar if available
  # 2. Falls back to text-based progress reporting when no progress bar
  # 3. Tracks progress using instance variables from progress_bar setup
  # 4. Outputs to STDERR for consistency with rake task logging
  #
  # == Examples:
  #   update_progress(bar)  # => true
  #   # Output: Processing 5 of 100
  #
  #   update_progress(bar, "Completed philosopher")  # => true
  #   # Output: Completed philosopher – processing 5 of 100
  #
  # == Used by:
  # - Called after each item in a loop within rake tasks
  # - Works with progress_bar() for consistent progress tracking
  # - Essential for user feedback in long-running batch operations
  #
  # == Notes:
  # - Always returns true for easy use in conditional expressions
  # - Uses STDERR to avoid interfering with task output redirection
  # - Requires prior call to progress_bar() to initialize @progress and @total
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
