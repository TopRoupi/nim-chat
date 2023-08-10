import os
import threadpool
import protocol
import asyncdispatch, asyncnet
import json

type
  ClientServer* = ref object
    socket*: AsyncSocket
    address*: string
    messages*: seq[Message]
    port*: int

proc newClientServer*(port: int): ClientServer =
  result = ClientServer(
    socket: newAsyncSocket(),
    address: "localhost",
    port: port
  )

proc connect*(self: ClientServer) {.async.} =
  await self.socket.connect(self.address, self.port.Port)

proc disconnect*(self: ClientServer) =
  self.socket.close()

proc listenForMessages*(self: ClientServer) {.async.} =
  while true:
    let line = await self.socket.recvLine()
    let message = parseJson(line).toMessage()
    self.messages.add(message)
    echo message.username, " said: ", message.message

proc sendMessage*(self: ClientServer, message: Message) {.async.} =
  let payload = %message
  echo payload
  await self.socket.send($payload & "\n")

proc start*(self: ClientServer) =
  asyncCheck self.connect()
  asyncCheck self.listenForMessages()

  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      let message = Message(username: "anonymous", message: ^messageFlowVar)
      asyncCheck self.sendMessage(message)
      messageFlowVar = spawn stdin.readLine()
    asyncdispatch.poll()

when isMainModule:
  echo "chat app started"

  let clientServer = newClientServer(3010)
  clientServer.start()
