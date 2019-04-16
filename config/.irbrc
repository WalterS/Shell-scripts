begin
  require 'wirble'
  require 'hirb'

  # Syntax highlighting with wirble
  if Object.const_defined?('Wirble')
    Wirble.init
    Wirble.colorize
  end
rescue LoadError => e
  STDERR.puts e.class.name + ': ' + e.message
end

require 'json'
require 'yaml'

# History configuration
IRB.conf[:HISTORY_SIZE] = 10_000
IRB.conf[:HISTORY_FILE] = File.expand_path('~/.irb_history')

# Prompt configuration
IRB.conf[:PROMPT][:CUSTOM] = {
  PROMPT_I: 'irb>> ',
  PROMPT_S: 'irb %l>> ',
  PROMPT_C: ' ',
  PROMPT_N: ' ',
  RETURN: "=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:BACK_TRACE_LIMIT] = 100

# Method for reloading gems
def reload(require_regex)
  $LOADED_FEATURES.grep(/^#{require_regex}/).each { |e| $LOADED_FEATURES.delete(e) && require(e) }
end

# (Un-)silence output
def silence
  if irb_context.echo
    irb_context.echo = false
    puts 'silence on'
  else
    irb_context.echo = true
    puts 'silence off'
  end
end

# Check for verbosity state
def silence?
  if irb_context.echo
    puts 'silence is off'
  else
    puts 'silence is on'
  end
end
