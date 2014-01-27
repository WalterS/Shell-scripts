About
=====
A collection of shell scripts (sh, bash, expect) for Linux.

A lot of the Bash scripts need a fairly current version (> 3.2) of Bash due to the usage of [brace expansions](http://www.tldp.org/LDP/abs/html/special-chars.html#BRACEEXPREF), [string](http://www.tldp.org/LDP/abs/html/string-manipulation.html) and [arithmetic operations](http://www.tldp.org/LDP/abs/html/ops.html#AROPS1) or the use of [arrays](http://www.tldp.org/LDP/abs/html/arrays.html).

If you experience unexpected behaviour when running one of the Bash scripts check if you are really running Bash by typing `echo $BASH_VERSION` in your terminal or console. If it returns empty your Bash might just be a link to another shell like Dash. You can check this by typing `ls -la $(which bash)`.


