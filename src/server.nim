import asyncdispatch, asyncnet

type
  Client* = ref object
    socket*: AsyncSocket
    netAddr*: string
    id*: int
    connected*: bool

proc `$`(client: Client): string =
  $client.id & " (" & client.netAddr & ")"

proc disconnect(self: Client): void =
  self.connected = false
  self.socket.close()




type
  Server* = ref object
    socket*: AsyncSocket
    clients*: seq[Client]
    port*: int

proc newServer*(port: int): Server =
  Server(socket: newAsyncSocket(), clients: @[], port: port)

proc startListening*(server: Server) =
  server.socket.bindAddr(server.port.Port, "localhost")
  server.socket.listen()

proc processMessages*(server: Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()
    echo "received message ", line
    if line.len == 0:
      client.disconnect()
      return
    echo client, " sent: ", line
    for c in server.clients:
      if c.id != client.id and c.connected:
        await c.socket.send(line & "\n")

proc loop*(server: Server) {.async.} =
  server.startListening()

  while true:
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    echo "accepted connection from ", netAddr
    let client = Client(
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true
    )
    server.clients.add(client)
    asyncCheck processMessages(server,client)
    asyncdispatch.poll()


when isMainModule:
  var server = newServer(3010)
  waitFor loop(server)
