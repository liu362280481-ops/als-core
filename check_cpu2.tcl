connect
targets -set -filter {name =~ "Cortex-A53 #0"}
stop
after 500
targets
exit
