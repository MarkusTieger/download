
chatSendEventClass = java.resolveClass("de.markustieger.tac.v5.event.impl.ChatMessageSendedEvent")

function onChatMessageSended(message)
  if message == "pause" then
    gui.openScreen(java.lua_newInstance("net.minecraft.client.gui.screen.GameMenuScreen", true))
  end
end

event.registerListener(chatSendEventClass, 0, java.functionToConsumer(onChatMessageSended))
