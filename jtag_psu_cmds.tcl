connect
targets -set -nocase -filter {name =~ "PSU"}
puts "PSU target selected"
puts "Available commands - trying various memory ops:"
mrd 0x00100000 4
exit
