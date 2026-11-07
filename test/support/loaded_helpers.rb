module LoadedHelpers
  def self.wrapper(path)
    @wrappers ||= {}
    @wrappers[path] ||= begin
      modules = ObjectSpace.each_object(Module).to_a
      load path, true
      wrapper = (ObjectSpace.each_object(Module).to_a - modules).find do |candidate|
        (candidate.instance_methods(false) + candidate.private_instance_methods(false)).any? do |method|
          candidate.instance_method(method).source_location&.first == path
        end
      end
      raise "No helper methods loaded from #{path}" unless wrapper
      wrapper.send(:public, *wrapper.private_instance_methods(false))
      wrapper
    end
  end

  def load_helpers(relative_path)
    Object.new.extend(LoadedHelpers.wrapper(Rails.root.join(relative_path).to_s))
  end
end
