require 'wirble'

# Syntax highlighting
Wirble.init
Wirble.colorize

#History configuration
IRB.conf[:HISTORY_SIZE] = 10000

# Prompt configuration
IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_I => "irb>> ",
  :PROMPT_S => "irb %l>> ",
  :PROMPT_C => " ",
  :PROMPT_N => " ",
  :RETURN => "=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM
IRB.conf[:AUTO_INDENT] = true

