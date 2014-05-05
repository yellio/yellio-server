var addUser, io, removeUser, rooms, stunServers;

io = require('socket.io')();

stunServers = require('./config/webRTC');

rooms = {};

addUser = function(user) {
  var newRoom;
  if (rooms[user.room]) {
    return rooms[user.room][user.name] = user.id;
  } else {
    newRoom = {};
    newRoom[user.name] = user.id;
    return rooms[user.room] = newRoom;
  }
};

removeUser = function(user) {
  return delete rooms[user.room][user.name];
};

io.on('connection', function(socket) {
  socket.emit('availiable rooms', rooms);
  socket.emit('stun servers', stunServers);
  return socket.on('join room', function(user) {
    console.log("" + user.name + " joins " + user.room);
    user.id = socket.id;
    addUser(user);
    socket.join(user.room);
    socket.broadcast.to(user.room).emit('user joined', user);
    socket.broadcast.emit('availiable rooms', rooms);
    socket.emit('room info', rooms[user.room]);
    socket.on('call request', function(data) {
      var recipient;
      console.log("call request from " + user.name + " to " + data.username);
      recipient = io.sockets.connected[rooms[user.room][data.username]];
      return recipient.emit('incoming call', {
        desc: data.desc,
        username: user.name
      });
    });
    socket.on('call accept', function(data) {
      var recipient;
      console.log("" + user.name + " accepts call from " + data.username);
      recipient = io.sockets.connected[rooms[user.room][data.username]];
      return recipient.emit('call accepted', data.desc);
    });
    socket.on('disconnect', function() {
      console.log("" + user.name + " disconnected");
      socket.broadcast.to(user.room).emit('user disconnected', user.name);
      removeUser(user);
      return socket.broadcast.emit('availiable rooms', rooms);
    });
    return socket.on('send candidate', function(data) {
      var recipient;
      recipient = io.sockets.connected[rooms[user.room][data.username]];
      return recipient.emit('ice candidate', data.candidate);
    });
  });
});

io.listen(3000);
