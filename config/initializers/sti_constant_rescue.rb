# Rescue handler for STI subclass constant resolution failures
# When Rails tries to instantiate a STI subclass (Philosopher, Work) but the
# constant isn't loaded yet, we auto-load it from the Shadow model
#
# This is particularly useful in:
# - Rails runner scripts that don't eager load all models
# - Background jobs and rake tasks
# - Console sessions with selective requires

# Automatically define the STI subclasses as constants if they're not loaded
# This ensures that Philosopher and Work constants are always available
unless defined?(Philosopher)
  class Philosopher < Shadow
  end
end

unless defined?(Work)
  class Work < Shadow
  end
end

# Add a const_missing hook to Object to automatically load STI subclasses
# This catches cases where code references Philosopher or Work before they're loaded
class Object
  class << self
    alias_method :const_missing_without_sti_rescue, :const_missing if method_defined?(:const_missing)

    def const_missing(name)
      # If someone is looking for Philosopher or Work, load them from Shadow
      if name == :Philosopher && defined?(Shadow)
        Rails.logger.info "Auto-loading Philosopher constant from Shadow STI"
        return ::Philosopher if defined?(::Philosopher)
        ::Object.const_set(:Philosopher, Class.new(Shadow))
      elsif name == :Work && defined?(Shadow)
        Rails.logger.info "Auto-loading Work constant from Shadow STI"
        return ::Work if defined?(::Work)
        ::Object.const_set(:Work, Class.new(Shadow))
      end

      # Fall back to original behavior
      if respond_to?(:const_missing_without_sti_rescue)
        const_missing_without_sti_rescue(name)
      else
        raise NameError, "uninitialized constant #{name}"
      end
    end
  end
end

module ActiveRecord
  module Inheritance
    module ClassMethods
      # Override the find_sti_class method to rescue NameError
      def find_sti_class_with_rescue(type_name)
        find_sti_class_without_rescue(type_name)
      rescue NameError => e
        # Only rescue if it's specifically about our STI subclasses
        if e.message =~ /uninitialized constant (Philosopher|Work)\b/
          Rails.logger.warn "STI constant #{$1} not loaded, using base Shadow class"
          # Return the base class (Shadow) instead of the subclass
          Shadow
        else
          raise
        end
      end

      # Alias chain to preserve original behavior
      alias_method :find_sti_class_without_rescue, :find_sti_class
      alias_method :find_sti_class, :find_sti_class_with_rescue
    end
  end
end

# Also patch the instantiation logic to handle cases where we're trying to
# query for a specific STI type that isn't loaded
module ActiveRecord
  class Relation
    def exec_queries_with_sti_rescue
      exec_queries_without_sti_rescue
    rescue NameError => e
      if e.message =~ /uninitialized constant (Philosopher|Work)\b/
        Rails.logger.warn "STI query failed for #{$1}, returning empty relation"
        # Return an empty result set
        @records = []
        @loaded = true
        @records
      else
        raise
      end
    end

    alias_method :exec_queries_without_sti_rescue, :exec_queries
    alias_method :exec_queries, :exec_queries_with_sti_rescue
  end
end
