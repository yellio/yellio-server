io = require('socket.io')()
stunServers = require './config/webRTC'

rooms = {}

addUser = (user) ->
  if rooms[user.room]
    rooms[user.room][user.name] = user.id
  else
    newRoom = {}
    newRoom[user.name] = user.id
    rooms[user.room] = newRoom

removeUser = (user) ->
  delete rooms[user.room][user.name]

io.on 'connection', (socket) ->

  socket.emit 'availiable rooms', rooms
  socket.emit 'stun servers', stunServers

  socket.on 'join room', (user) ->

    console.log "#{user.name} joins #{user.room}"
    user.id = socket.id
    addUser user
    socket.join user.room

    socket.broadcast.to(user.room).emit 'user joined', user

    # Update homepage stats
    socket.broadcast.emit 'availiable rooms', rooms

    socket.emit 'room info', rooms[user.room]

    socket.on 'leave room', ->
      console.log "#{user.name} leaves #{user.room}"
      removeUser user
      socket.broadcast.to(user.room).emit 'user disconnected', user.name
      socket.emit 'availiable rooms', rooms

    socket.on 'call request', (data) ->
      console.log "call request from #{user.name} to #{data.username}"
      recipient = io.sockets.connected[rooms[user.room][data.username]]
      recipient.emit 'incoming call', {desc: data.desc, username: user.name}

    socket.on 'renegotiation request', (data) ->
      console.log "renegotiation request from #{user.name} to #{data.username}"
      recipient = io.sockets.connected[rooms[user.room][data.username]]
      recipient.emit 'renegotiation', {desc: data.desc, username: user.name}

    socket.on 'call accept', (data) ->
      console.log "#{user.name} accepts call from #{data.username}"
      recipient = io.sockets.connected[rooms[user.room][data.username]]
      recipient.emit 'call accepted', data.desc

    socket.on 'disconnect', ->
      console.log "#{user.name} disconnected"
      socket.broadcast.to(user.room).emit 'user disconnected', user.name
      removeUser user
      socket.broadcast.emit 'availiable rooms', rooms

    socket.on 'send candidate', (data) ->
      recipient = io.sockets.connected[rooms[user.room][data.username]]
      recipient.emit 'ice candidate', data.candidate


io.listen 3000
