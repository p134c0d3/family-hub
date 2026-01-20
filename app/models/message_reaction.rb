# frozen_string_literal: true

# MessageReaction model for Family Hub
#
# Represents an emoji reaction to a message. Each user can add multiple
# different emoji reactions to a message, but only one of each emoji type.
#
class MessageReaction < ApplicationRecord
  # Quick-access emoji reactions (shown first)
  QUICK_EMOJIS = %w[👍 ❤️ 😂 😮 😢 🎉].freeze

  # Full emoji set organized by category
  EMOJI_CATEGORIES = {
    'Smileys' => %w[😀 😃 😄 😁 😆 😅 🤣 😂 🙂 😊 😇 🥰 😍 🤩 😘 😗 😋 😛 😜 🤪 😝 🤗 🤭 🤫 🤔 🤐 🤨 😐 😑 😶 😏 😒 🙄 😬 🤥 😌 😔 😪 🤤 😴 😷 🤒 🤕 🤢 🤮 🤧 🥵 🥶 🥴 😵 🤯 🤠 🥳 🥸 😎 🤓 🧐 😕 😟 🙁 😮 😯 😲 😳 🥺 😦 😧 😨 😰 😥 😢 😭 😱 😖 😣 😞 😓 😩 😫 🥱 😤 😡 😠 🤬 👿 💀 💩 🤡 👹 👺 👻 👽 👾 🤖],
    'Gestures' => %w[👋 🤚 🖐 ✋ 🖖 👌 🤌 🤏 ✌️ 🤞 🤟 🤘 🤙 👈 👉 👆 🖕 👇 ☝️ 👍 👎 ✊ 👊 🤛 🤜 👏 🙌 👐 🤲 🤝 🙏 💪 🦾 🦿 🦵 🦶],
    'Hearts' => %w[❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 💖 💘 💝 💟],
    'Celebration' => %w[🎉 🎊 🎈 🎁 🎀 🪅 🎂 🍰 🧁 🎄 🎃 🎆 🎇 🧨 ✨ 🎋 🎍 🎎 🎏 🎐 🏆 🥇 🥈 🥉 🏅 🎖 🎗],
    'Animals' => %w[🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔 🐧 🐦 🐤 🦆 🦅 🦉 🦇 🐺 🐗 🐴 🦄 🐝 🐛 🦋 🐌 🐞 🐜 🦟 🦗 🕷],
    'Food' => %w[🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🫐 🍈 🍒 🍑 🥭 🍍 🥥 🥝 🍅 🥑 🍆 🥦 🥬 🥒 🌶 🫑 🌽 🥕 🧄 🧅 🥔 🍠 🥐 🥯 🍞 🥖 🥨 🧀 🍕 🍔 🍟 🌭 🍿 🧂 🥤 🧃 🧉 🍵 ☕ 🍺 🍻 🥂 🍷 🍸 🍹],
    'Activities' => %w[⚽ 🏀 🏈 ⚾ 🥎 🎾 🏐 🏉 🥏 🎱 🪀 🏓 🏸 🏒 🏑 🥍 🏏 🪃 🥅 ⛳ 🪁 🏹 🎣 🤿 🥊 🥋 🎽 🛹 🛼 🛷 ⛸ 🥌 🎿 ⛷ 🏂 🪂 🏋️ 🤼 🤸 ⛹️ 🤺 🤾 🏌️ 🏇 ⛳ 🧘 🏄 🏊 🤽 🚣 🧗 🚴 🚵],
    'Objects' => %w[⌚ 📱 💻 ⌨️ 🖥 🖨 🖱 💽 💾 💿 📀 🎥 🎬 📺 📷 📸 📹 📼 🔍 🔎 💡 🔦 🏮 📔 📕 📖 📗 📘 📙 📚 📓 📒 📃 📜 📄 📰 🗞 📑 🔖 💰 💴 💵 💶 💷 💳 🧾 💎 ⚖️ 🔧 🔨 ⚒ 🛠 ⛏ 🔩 ⚙️ 🔫 💣 🔪 🗡 ⚔️ 🛡 🔑 🗝 🔐 🔒 🔓],
    'Symbols' => %w[❤️ 💯 ✅ ❌ ⭕ 🚫 💢 ♨️ 🚷 🚯 🚳 🚱 🔞 📵 🔇 🔕 🔔 ❗ ❓ ❕ ❔ ‼️ ⁉️ 💤 💬 💭 🗯 💠 Ⓜ️ 🅰️ 🅱️ 🆎 🆑 🅾️ 🆘 ⛔ 📛 🚨 🔴 🟠 🟡 🟢 🔵 🟣 ⚫ ⚪ 🟤 🔺 🔻 🔸 🔹 🔶 🔷 ▪️ ▫️ ⬛ ⬜ 🟥 🟧 🟨 🟩 🟦 🟪 ⏩ ⏪ ⏫ ⏬ ➡️ ⬅️ ⬆️ ⬇️]
  }.freeze

  # Alias for backward compatibility
  COMMON_EMOJIS = QUICK_EMOJIS

  # Associations
  belongs_to :message
  belongs_to :user

  # Validations
  validates :emoji, presence: true
  validates :user_id, uniqueness: { scope: [:message_id, :emoji], message: "has already reacted with this emoji" }

  # Scopes
  scope :for_emoji, ->(emoji) { where(emoji: emoji) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create_commit :broadcast_reaction_added
  after_destroy_commit :broadcast_reaction_removed

  # Class methods

  # Get reaction counts grouped by emoji for a message
  def self.grouped_counts
    group(:emoji).count
  end

  private

  # Broadcast when a reaction is added
  def broadcast_reaction_added
    # Will be implemented with ActionCable
    # ChatChannel.broadcast_to(message.chat, { type: 'reaction_added', reaction: self })
  end

  # Broadcast when a reaction is removed
  def broadcast_reaction_removed
    # Will be implemented with ActionCable
    # ChatChannel.broadcast_to(message.chat, { type: 'reaction_removed', reaction: self })
  end
end
