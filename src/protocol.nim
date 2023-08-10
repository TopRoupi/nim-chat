import json

type
  Message* = object
    username*: string
    message*: string

proc `%`*(self: Message): JsonNode =
  result = %{
    "username": %self.username,
    "message": %self.message
  }

proc toMessage*(self: JsonNode): Message =
  result = Message(
    username: self["username"].getStr(),
    message: self["message"].getStr()
  )
#
# proc jsonStringToMessage*(data:string): Message =
#   let dataJson = parseJson(data)
#   result.username = dataJson["username"].getStr()
#   result.message = dataJson["message"].getStr()
#
# proc messageToJsonString*(message: Message): string =
#   result = $(%{
#     "username": %message.username,
#       "message": %message.message
#     })
