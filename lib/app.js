var addUser, io, removeUser, rooms, stunServers;

io = require('socket.io')();

stunServers = require('./config/webRTC');

rooms = {};

addUser = function(user) {
  var newRoom;
  if (rooms[user.room]) {
    return rooms[user.room][user.name] = user.description;
  } else {
    newRoom = {};
    newRoom[user.name] = user.description;
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
    addUser(user);
    socket.join(user.room);
    socket.broadcast.to(user.room).emit('user joined', user);
    socket.broadcast.emit('availiable rooms', rooms);
    socket.emit('room info', rooms[user.room]);
    socket.on('call request', function(desc) {
      console.log("call request from " + user.name);
      return socket.broadcast.to(user.room).emit('incoming call', desc);
    });
    socket.on('call accept', function(desc) {
      console.log("call accept from " + user.name);
      return socket.broadcast.to(user.room).emit('call accepted', desc);
    });
    socket.on('disconnect', function() {
      console.log("" + user.name + " disconnected");
      socket.broadcast.to(user.room).emit('user disconnected', user.name);
      removeUser(user);
      return socket.broadcast.emit('availiable rooms', rooms);
    });
    return socket.on('send candidate', function(candidate) {
      console.log("send candidate from " + user.name);
      return socket.broadcast.to(user.room).emit('ice candidate', candidate);
    });
  });
});

io.listen(3000);
