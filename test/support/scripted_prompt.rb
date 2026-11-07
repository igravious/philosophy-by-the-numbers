class ScriptedPrompt
  Menu = Struct.new(:choices) do
    def choice(label, value)
      choices << [label, value]
    end
  end

  attr_reader :answers, :questions, :messages, :menus

  def initialize(*answers)
    @answers = answers
    @questions = []
    @messages = []
    @menus = []
  end

  def select(question, choices = nil, **options)
    @questions << [question, choices, options]
    if block_given?
      menu = Menu.new([])
      yield menu
      @menus << menu.choices
    end
    next_answer
  end

  def yes?(question, **options)
    @questions << [question, options]
    next_answer
  end

  def ask(question, **options)
    @questions << [question, options]
    next_answer
  end

  def keypress(message)
    @messages << message
  end

  def say(message)
    @messages << message
  end

  private

  def next_answer
    raise "Prompt received an unexpected question" if @answers.empty?
    @answers.shift
  end
end
