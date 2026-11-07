module ScriptRunner
  def self.next_collection
    @collection = (@collection || 0) + 1
  end

  def load_script(path)
    path = File.expand_path(path)
    if defined?(SimpleCov) && SimpleCov.running
      previous = Coverage.peek_result[path]
      if previous
        result = SimpleCov::Result.new(path => previous)
        result.command_name = "Script load #{Process.pid} #{ScriptRunner.next_collection}"
        SimpleCov::ResultMerger.store_result(result)
      end
    end
    load path, true
  end
end
