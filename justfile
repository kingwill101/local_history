build:
  dart build cli

daemon: 
  just lh daemon
  
lh *ARGS:
  ./build/cli/linux_x64/bundle/bin/local_history {{ARGS}}