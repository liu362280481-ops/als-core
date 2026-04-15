connect
targets -set -nocase -filter {name =~ "*PSU*"}
puts "Reading boot mode register at 0xFF5E003C..."
mrd 0xFF5E003C 1
puts "Reading RPUCOMMAND register..."
mrd 0xFFCC0000 1
exit
