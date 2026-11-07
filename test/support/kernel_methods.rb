module KernelMethods
  private

  def with_script_arguments(*arguments)
    original = ARGV.dup
    ARGV.replace(arguments)
    yield
  ensure
    ARGV.replace(original)
  end

  def with_kernel_method(name, replacement)
    original = Kernel.instance_method(name) if Kernel.method_defined?(name) || Kernel.private_method_defined?(name)
    Kernel.send(:define_method, name, replacement)
    Kernel.send(:private, name)
    yield
  ensure
    if original
      Kernel.send(:define_method, name, original)
      Kernel.send(:private, name)
    else
      Kernel.send(:remove_method, name)
    end
  end
end
