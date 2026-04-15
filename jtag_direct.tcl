connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts "Check targets:"
puts [targets]

puts "Select A53 #0 (target 10)..."
targets -set 10

puts "Try dow WITHOUT stop..."
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts "Go..."
con

puts "Done."
exit
