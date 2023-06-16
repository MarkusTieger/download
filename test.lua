
chatSendEventClass = java.resolveClass("de.markustieger.tac.v5.event.impl.ChatMessageSendedEvent")

function onChatMessageSended(message)
  
end

event.registerListener(chatSendEventClass, 0, java.functionToConsumer(onChatMessageSended))
