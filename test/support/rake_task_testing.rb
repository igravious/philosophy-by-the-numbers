require "rake"

module RakeTaskTesting
  Progress = Struct.new(:count) do
    def increment!
      self.count += 1
    end
  end

  def self.application(path)
    @applications ||= {}
    @applications[path] ||= begin
      original = Rake.application
      Rake.application = Rake::Application.new
      Rake::Task.define_task(:environment)
      load path, true
      Rake.application
    ensure
      Rake.application = original
    end
  end

  def use_rake_tasks(path)
    @original_rake = Rake.application
    Rake.application = RakeTaskTesting.application(File.expand_path(path))
    Rake::Task.tasks.each(&:reenable)
  end

  def restore_rake_tasks
    Rake.application = @original_rake
  end

  def with_task_progress(receiver, &block)
    receiver.stub(:progress_bar, Progress.new(0), &block)
  end
end
