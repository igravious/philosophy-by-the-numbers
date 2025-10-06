# frozen_string_literal: true

require 'knowledge'
require_relative '../console_extension'

# Wikidata SPARQL Query Execution Utility
#
# This module provides centralized SPARQL query execution with:
# - Comprehensive logging (query details, timing, results)
# - Progress spinner for long-running queries  
# - Automatic retry logic for timeout errors
# - Standardized error handling
#
# Usage Examples:
#
# # For large/important queries with full error handling:
# results = Wikidata::QueryExecutor.execute(
#   query_string, 
#   'my_query_name',
#   {
#     task_name: 'my_rake_task',
#     metadata: { description: 'What this query does' },
#     max_retries: 5
#   }
# )
#
# # For quick/simple queries:
# results = Wikidata::QueryExecutor.execute_simple(query_string, 'simple_query')
#
# # Convenience methods for common operations:
# philosophers = Wikidata::QueryExecutor.execute_philosopher_query
# philosopher = Wikidata::QueryExecutor.find_philosopher_by_id('Q5891')
#
module Wikidata
  module QueryExecutor
    include Knowledge
    
    class << self
      # Execute a SPARQL query with full logging, timing, retry logic, and progress spinner
      # Use this for important/large queries that need robust error handling
      # @param query_string [String] The SPARQL query to execute
      # @param query_name [String] Human-readable name for the query (for logging)
      # @param options [Hash] Additional options
      # @option options [String] :task_name Name of the rake task calling this
      # @option options [Hash] :metadata Additional metadata to log
      # @option options [Integer] :max_retries Number of retry attempts (default: 3)
      # @option options [Boolean] :show_spinner Whether to show progress spinner (default: true)
      # @return [Array] Query results
      def execute(query_string, query_name, options = {})
        # Set defaults
        task_name = options[:task_name] || 'unknown_task'
        metadata = options[:metadata] || {}
        max_retries = options[:max_retries] || 3
        show_spinner = options.fetch(:show_spinner, true)
        
        # Initialize client
        client = Knowledge::Wikidata::Client.new
        
        # Log the query if debugging is enabled
        if ENV['SPARQL_DEBUG'] == 'true' || ENV['SPARQL_LOG'] == 'true'
          log_sparql_query(query_string, query_name, {
            task: task_name,
            **metadata
          })
        end
        
        # Execute with retry logic
        result = nil
        retry_count = 0
        
        begin
          spinner_text = "Executing #{query_name} query (attempt #{retry_count + 1}/#{max_retries})"
          
          if show_spinner
            spinner = ProgressSpinner.new(spinner_text)
            spinner.start
          else
            puts spinner_text
          end
          
          # Execute the query
          start_time = Time.now
          result = client.query(query_string)
          end_time = Time.now
          
          duration = ((end_time - start_time) * 1000).round(2) # milliseconds
          
          if show_spinner
            spinner.stop("✓ #{query_name} completed (#{duration}ms, #{result.length} results)")
          else
            puts "✓ #{query_name} completed (#{duration}ms, #{result.length} results)"
          end
          
          log_task_output("✓ #{query_name} query completed successfully: #{result.length} results in #{duration}ms", "#{task_name}_query")
          
        rescue Net::ReadTimeout => e
          if show_spinner
            spinner&.stop("✗ #{query_name} timed out")
          else
            puts "✗ #{query_name} timed out"
          end
          
          retry_count += 1
          if retry_count < max_retries
            backoff_time = retry_count * 5 # Progressive backoff: 5s, 10s, 15s
            log_task_output("⚠ #{query_name} timed out (attempt #{retry_count}/#{max_retries}). Retrying in #{backoff_time} seconds...", "#{task_name}_retry")
            sleep(backoff_time)
            retry
          else
            log_task_output("✗ #{query_name} failed after all retry attempts: #{e.message}", "#{task_name}_error")
            raise e
          end
        rescue => e
          if show_spinner
            spinner&.stop("✗ #{query_name} failed")
          else
            puts "✗ #{query_name} failed"
          end
          
          log_task_output("✗ #{query_name} failed with error: #{e.message}", "#{task_name}_error")
          raise e
        end
        
        result
      end
      
      # Execute a simple SPARQL query with basic logging but no retry logic or spinner
      # Use this for quick/small queries where full error handling isn't needed
      # @param query_string [String] The SPARQL query to execute  
      # @param query_name [String] Human-readable name for the query (for logging)
      # @param options [Hash] Additional options
      # @option options [String] :task_name Name of the rake task calling this
      # @option options [Boolean] :log_query Whether to log the query (default: false for quick queries)
      # @return [Array] Query results
      def execute_simple(query_string, query_name = 'simple_query', options = {})
        task_name = options[:task_name] || 'unknown_task'
        log_query = options.fetch(:log_query, false)
        
        # Initialize client
        client = Knowledge::Wikidata::Client.new
        
        # Log the query if requested or if debugging is enabled
        if log_query || ENV['SPARQL_DEBUG'] == 'true'
          log_sparql_query(query_string, query_name, {
            task: task_name,
            query_type: 'simple'
          })
        end
        
        # Execute the query with basic timing
        start_time = Time.now
        result = client.query(query_string)
        end_time = Time.now
        
        duration = ((end_time - start_time) * 1000).round(2) # milliseconds
        
        if ENV['SPARQL_DEBUG'] == 'true'
          puts "✓ #{query_name} completed (#{duration}ms, #{result.length} results)"
        end
        
        result
      end
      
      # Convenience methods for common query patterns
      
      # Execute the main philosopher population query
      def execute_philosopher_query(options = {})
        execute(
          Wikidata::SparqlQueries::THESE_PHILOSOPHERS,
          'populate_philosophers',
          {
            task_name: 'shadow:philosopher:populate',
            metadata: { query_type: 'optimized (with sitelink counting)' },
            **options
          }
        )
      end
      
      # Find philosopher by Wikidata entity ID
      def find_philosopher_by_id(entity_id, options = {})
        query = Wikidata::SparqlQueries::FIND_BY_ID % {interpolated_entity: entity_id}
        execute_simple(query, "find_philosopher_#{entity_id}", {
          task_name: options[:task_name] || 'unknown_task'
        })
      end
      
      # Find philosopher by name
      def find_philosopher_by_name(name, options = {})
        query = Wikidata::SparqlQueries::FIND_BY_NAME % {interpolated_entity: name}
        execute_simple(query, "find_philosopher_#{name}", {
          task_name: options[:task_name] || 'unknown_task'
        })
      end
      
      # Execute philosophical works queries
      def execute_philosophical_works_query(options = {})
        execute(
          Wikidata::SparqlQueries::THESE_PHILOSOPHICAL_WORKS,
          'philosophical_works',
          {
            task_name: 'shadow:work:philosophical_works',
            **options
          }
        )
      end
      
      # Execute works by philosophers query
      def execute_works_by_philosophers_query(options = {})
        execute(
          Wikidata::SparqlQueries::THESE_WORKS_BY_PHILOSOPHERS,
          'works_by_philosophers',
          {
            task_name: 'shadow:work:works_by_philosophers',
            **options
          }
        )
      end
      
      # Execute entity attribute query
      def execute_entity_attributes_query(entity_id, options = {})
        query = Wikidata::SparqlQueries::ATTR_ % {interpolated_entity: entity_id}
        execute_simple(query, "entity_attributes_#{entity_id}", {
          task_name: options[:task_name] || 'entity_attributes'
        })
      end
      
      # Execute hits filter query
      def execute_hits_query(entity_id, filter_expression, options = {})
        query = Wikidata::SparqlQueries::HITS2 % {
          interpolated_entity: entity_id,
          interpolated_filter: filter_expression
        }
        execute_simple(query, "hits_#{entity_id}", {
          task_name: options[:task_name] || 'hits_query'
        })
      end
      
      # Performance monitoring: Get query performance stats
      def performance_stats
        log_file = File.join(Rails.root, 'log', 'task_output.log')
        return {} unless File.exist?(log_file)
        
        stats = {
          total_queries: 0,
          avg_duration: 0,
          total_results: 0,
          fastest_query: { duration: Float::INFINITY, name: nil },
          slowest_query: { duration: 0, name: nil },
          query_counts: Hash.new(0)
        }
        
        durations = []
        
        File.readlines(log_file).each do |line|
          if line.match(/✓ (\w+) query completed successfully: (\d+) results in ([\d.]+)ms/)
            query_name = $1
            result_count = $2.to_i
            duration = $3.to_f
            
            stats[:total_queries] += 1
            stats[:total_results] += result_count
            stats[:query_counts][query_name] += 1
            durations << duration
            
            if duration < stats[:fastest_query][:duration]
              stats[:fastest_query] = { duration: duration, name: query_name }
            end
            
            if duration > stats[:slowest_query][:duration]
              stats[:slowest_query] = { duration: duration, name: query_name }
            end
          end
        end
        
        stats[:avg_duration] = durations.empty? ? 0 : (durations.sum / durations.length).round(2)
        stats
      end
      
      private
      
      # Log SPARQL query details to file and console
      def log_sparql_query(query_string, query_name, metadata = {})
        require_relative 'client_helpers'
        Wikidata::ClientHelpers.log_sparql_query(query_string, query_name, metadata)
      end
      
      # Log task output to file and console
      def log_task_output(message, category = 'general')
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        log_message = "[#{timestamp}] [#{category}] #{message}"
        
        # Write to log file
        log_dir = File.join(Rails.root, 'log')
        Dir.mkdir(log_dir) unless Dir.exist?(log_dir)
        
        File.open(File.join(log_dir, 'task_output.log'), 'a') do |f|
          f.puts log_message
        end
        
        # Also output to console
        puts log_message
      end
    end
  end
end