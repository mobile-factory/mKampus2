# Skrypt do zabijania zawieszonego serwera StackMoba

util = require('util')
exec = require('child_process').exec

child = exec 'ps ax | grep stackmob', (error, stdout, stderr) ->
  lines = stdout.split("\n")
  for line in lines
    if line.indexOf("stackmob server") > -1
      parts = line.split(" ")
      if parts[0] == " "
        pid = parts[1]
      else
        pid = parts[0]
      console.log "killing", pid
      process.kill pid, 'SIGKILL'
      break