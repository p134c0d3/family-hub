// Chat channel subscription for real-time messaging
import consumer from "./consumer"

// This will be initialized by the chat Stimulus controller
// when a user views a chat conversation

export function subscribeToChatChannel(chatId, callbacks) {
  return consumer.subscriptions.create(
    { channel: "ChatChannel", chat_id: chatId },
    {
      connected() {
        console.log(`Connected to chat ${chatId}`)
        if (callbacks.connected) callbacks.connected()
      },

      disconnected() {
        console.log(`Disconnected from chat ${chatId}`)
        if (callbacks.disconnected) callbacks.disconnected()
      },

      received(data) {
        console.log('Received:', data)

        switch (data.type) {
          case 'new_message':
            if (callbacks.onNewMessage) callbacks.onNewMessage(data)
            break
          case 'message_updated':
            if (callbacks.onMessageUpdated) callbacks.onMessageUpdated(data)
            break
          case 'message_deleted':
            if (callbacks.onMessageDeleted) callbacks.onMessageDeleted(data)
            break
          case 'reaction_added':
          case 'reaction_removed':
            if (callbacks.onReactionChange) callbacks.onReactionChange(data)
            break
          case 'typing':
            if (callbacks.onTyping) callbacks.onTyping(data)
            break
          default:
            console.log('Unknown message type:', data.type)
        }
      },

      // Send typing indicator
      typing(isTyping) {
        this.perform('typing', { is_typing: isTyping })
      },

      // Mark messages as read
      markRead() {
        this.perform('mark_read')
      }
    }
  )
}
