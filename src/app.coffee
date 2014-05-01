io = require('socket.io')()
stunServers = require './config/webRTC'

rooms = {}

addUser = (user) ->
  if rooms[user.room]
    rooms[user.room][user.name] = user.resources
  else
    newRoom = {}
    newRoom[user.name] = user.resources
    rooms[user.room] = newRoom

removeUser = (user) ->
  delete rooms[user.room][user.name]

io.on 'connection', (socket) ->

  socket.emit 'availiable rooms', rooms
  socket.emit 'stun servers', stunServers

  socket.on 'join room', (user) ->

    console.log "#{user.name} joins #{user.room}"
    addUser user
    socket.join user.room

    socket.broadcast.to(user.room).emit 'user joined', user
    socket.broadcast.emit 'availiable rooms', rooms

    socket.emit 'room info', rooms[user.room]

    socket.on 'message', (message) ->
      socket.broadcast.to(user.room).emit 'message',
        message: message
        user: user.name

    socket.on 'disconnect', ->
      console.log "#{user.name} disconnected"
      socket.broadcast.to(user.room).emit 'user disconnected', user.name
      removeUser user
      socket.broadcast.emit 'availiable rooms', rooms


io.listen 3000
