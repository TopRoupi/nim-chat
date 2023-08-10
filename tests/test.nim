import unittest2
import json
import "../src/protocol.nim"

suite "protocol":
  var dataJson = %{"username": %"john", "message": %"hi"}
  var dataJsonString = $dataJson
  var dataMessage = Message(
    username: dataJson["username"].getStr(),
    message: dataJson["message"].getStr()
    )

  test "should be able to convert json to message":
    var message: Message = dataJson.toMessage()
    check(message is Message)
    check(message == dataMessage)

  test "should be able to convert message to string":
    let message = %dataMessage
    check(message == dataJson)

import "../src/server.nim"
import "../src/client.nim"
import "../src/protocol.nim"
import threadpool
import asyncdispatch, asyncnet
import random

suite "server":
  randomize()
  let port = rand(4000..5000)
  let server = newServer(port)
  asyncCheck server.loop()
  # setup:
  #   let server = newServer(port)
  #   asyncCheck server.loop()
  #
  # teardown:
  #   for c in server.clients:
  #     c.socket.close()
  #   server.socket.close()

  test "clients count should increase a new client connects":
    let clientsCount = server.clients.len
    let client = newClientServer(port)
    waitFor client.connect()
    check(server.clients.len > clientsCount)

  test "server should broadcast messages to all other connected clients":
    let client1 = newClientServer(port)
    let client2 = newClientServer(port)
    let client3 = newClientServer(port)
    waitFor client1.connect()
    waitFor client2.connect()
    waitFor client3.connect()
    waitFor client1.sendMessage(Message(username: "anonymous", message: "hi"))
    asyncCheck client3.listenForMessages()
    asyncCheck client2.listenForMessages()
    asyncCheck client1.listenForMessages()
    for i in (0..10):
      asyncdispatch.poll()
    check(client1.messages.len == 0)
    check(client2.messages.len > 0)
    check(client3.messages.len > 0)

