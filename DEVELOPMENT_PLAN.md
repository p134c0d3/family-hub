# Family Hub - Development Plan

A Ruby on Rails 8 application for family members to communicate, share calendars, and exchange media.

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[~]` | In progress |
| `[x]` | Completed |

---

## Technology Stack

| Component | Technology | Notes |
|-----------|------------|-------|
| **Framework** | Ruby on Rails 8.1+ | Latest stable release |
| **Frontend** | Hotwire (Turbo + Stimulus) | Real-time without heavy JS |
| **Mobile** | Hotwire Native | iOS/Android via native shells (future) |
| **Database** | SQLite | Local development; upgradable later |
| **Styling** | TailwindCSS 4 | With custom theme config |
| **Real-time** | ActionCable + Solid Cable | No Redis dependency (Rails 8) |
| **Encryption** | Active Record Encryption (AES-256-GCM) | Built-in Rails encryption |
| **File Storage** | Active Storage | Local disk initially |
| **Image Processing** | libvips + image_processing gem | Compression & format conversion |
| **Video Processing** | FFmpeg + streamio-ffmpeg gem | Transcoding & compression |

---

## Core Design Decisions

### Authentication Flow
1. **First User** → Automatically becomes admin
2. **New Users** → Submit access request (name, email, DOB, city)
3. **Admin Approval** → Admin sets temporary password
4. **First Login** → User must change password
5. **User Statuses**: `active`, `inactive`, `removed`

### UI/UX Standards
- **Border Radius**: 15px (`rounded-[15px]` in Tailwind)
- **Color Palette**: Blue-based default (primary: slate-blue, accent: sky)
- **Animations**: Smooth transitions (300ms ease-in-out default)
- **Dark Mode**: CSS custom properties + class-based toggle
- **Mobile-First**: Responsive design for Hotwire Native

### Theme System
- **Admin creates preset themes** via palette builder (name + color picks)
- **Global default theme** set by admin
- **Per-user override** - users can select from available presets
- Theme colors: primary, secondary, accent, background, surface, text
- Stored as JSON in database, applied via CSS custom properties
- Falls back to system preference (light/dark) within chosen theme

### Media Processing Strategy

#### Image Processing
- **Compression**: Balanced (~50-60% size reduction)
- **Format Conversion**: HEIC/HEIF → WebP or JPEG, AVIF → WebP or JPEG
- **Tools**: libvips via `image_processing` gem
- **Variants**: Thumbnail (200px), Medium (800px), Full (original dimensions, compressed)

#### Video Processing
- **Compression**: Aggressive (prioritize storage savings)
- **Target Format**: H.264 MP4 (universal compatibility)
- **Resolution**: Cap at 1080p, scale down larger videos
- **Bitrate**: Variable bitrate, target ~2-4 Mbps for 1080p
- **Tools**: FFmpeg via `streamio-ffmpeg` gem
- **Processing**: Background job (videos take time to process)

---

## Sprint Progress

### Sprint 1: Messaging System 🔄 CURRENT

**Goal**: Build the core chat functionality as the foundation for real-time features.

#### 1.1 Project Setup
- [x] Create Rails 8 app with Tailwind
- [x] Configure Solid Cable for ActionCable
- [x] Set up Active Record Encryption
- [x] Configure Active Storage for file uploads
- [x] Create base layout with navbar
- [x] Implement theme switching (light/dark)
  - *Theme controller in Stimulus handles toggle*
  - *CSS custom properties for dynamic theming*
  - *Persists preference in localStorage*
- [x] Set up TailwindCSS with custom theme (blue palette, 15px radius)
  - *Custom @theme block in application.css*
  - *Utility classes: bg-theme-primary, text-theme-text, etc.*

#### 1.2 Authentication System
- [x] User model with has_secure_password
- [x] Login page (email/password)
- [x] Session management
- [x] Logout functionality
- [x] Force password change on first login (temp password flow)
  - *`password_changed` boolean on User model*
  - *`require_password_changed` before_action in controllers*
  - *Redirects to change_password_path until changed*

#### 1.3 Access Request System
- [x] Access Request model and migration
- [x] Request Access page (form with validations)
- [x] Basic admin approval workflow (temp password setting)
  - *Admin sets temporary password when approving*
  - *Custom modal system with confirm dialogs (replaced browser dialogs)*
  - *Form uses `data: { turbo: false }` for proper submission*
- [ ] Email notification on approval *(deferred - Action Mailer setup needed)*

#### 1.4 Core Chat Models
- [x] Chat model (direct, group, public)
- [x] ChatMembership model
- [x] Message model with encryption
- [x] MessageReaction model
  - *Expanded to 300+ emojis organized by category*
  - *QUICK_EMOJIS for fast access, EMOJI_CATEGORIES hash for full picker*
- [x] MessageReadReceipt model
- [x] MessageAttachment with Active Storage
  - *`has_many_attached :attachments` already on Message model*
  - *Added file validation: 100MB max, allowed types (images, videos, PDFs, docs)*
  - *Created `attachment_controller.js` for file selection, preview, and removal*
  - *Created `_attachments.html.erb` partial for displaying attachments*
  - *Images display as thumbnails with lightbox links*
  - *Videos display with native player controls*
  - *Documents display with file icon, name, size, and download link*

#### 1.5 Chat UI - List View
- [x] Chats index (list of conversations)
- [x] New chat form (direct message user search)
- [x] New group chat form
- [x] Chat preview cards with last message
- [x] Unread message badges
  - *`unread_count_for(user)` method on Chat model*
  - *Badge shows 99+ for counts over 99*

#### 1.6 Chat UI - Conversation View
- [x] Message list with infinite scroll
- [x] Message input with Stimulus controller
- [x] Send message with Turbo Stream
- [x] Real-time message delivery via ActionCable
  - *ChatChannel broadcasts new messages*
  - *Turbo Streams append messages to DOM*

#### 1.7 Advanced Chat Features
- [x] Edit message functionality
- [x] Delete message (soft delete)
  - *`deleted_at` timestamp, `display_content` shows "Message deleted"*
- [x] Emoji reactions picker (300+ emojis with categories)
  - *Categories: Smileys, Gestures, Hearts, Activities, Objects, Symbols, Flags*
  - *Scrollable picker with category headers*
  - *Quick reactions bar for common emojis*
- [x] Add/remove reactions with Turbo
- [x] Read receipts display
- [x] Typing indicators via ActionCable (continuous while typing)
  - *Sends typing status every 3 seconds while actively typing*
  - *Receiver timeout of 5 seconds before hiding indicator*
  - *Inline indicator above message input field*

#### 1.8 Threaded Replies
- [x] Parent message reference
- [x] Thread view UI
- [x] Reply to specific message
  - *Google Messages style reply preview*
  - *Shows parent message content preview above reply*
  - *Clickable to scroll to original message*
  - *Reply indicator while composing also shows content preview*
  - *Cancel reply button*
- [x] Thread notification logic
  - *NotificationService creates notifications when replying to someone's message*
  - *Real-time delivery via NotificationChannel (ActionCable)*
  - *Notification bell in navbar with unread count badge*

#### 1.9 @Mentions
- [x] Mention parser service
  - *MentionService parses @FirstName patterns from message content*
  - *Stores mentioned_user_ids JSON array on messages*
- [x] @username autocomplete
  - *Stimulus mention_controller.js detects @ in input*
  - *Fetches matching chat members via /chats/:id/mentions API*
  - *Keyboard navigation (↑/↓/Enter/Escape)*
- [x] Mention notifications
  - *Creates Notification records for each mentioned user*
  - *Broadcasts via NotificationChannel for real-time delivery*
  - *Toast notification appears for new mentions*
- [x] Highlight mentions in messages
  - *render_message_content helper wraps @mentions in styled spans*
  - *.mention CSS class with primary color and subtle background*

#### 1.10 File Sharing in Chat
- [x] Attachment upload via Active Storage
  - *Already implemented in 1.4 with attachment_controller.js*
- [x] Image preview in chat
  - *Smart grid layout with aspect ratio detection*
  - *Lightbox viewer with keyboard navigation (arrows, Escape)*
  - *Browse all images in chat conversation*
- [x] File download links
  - *Documents show filename, size, and download button*
- [x] 100MB file size validation
  - *Client-side check in attachment_controller.js*
  - *Server-side validation in Message model*

#### 1.11 Dashboard Integration
- [x] Recent chats widget (5 most recent)
  - *Uses `Chat.for_user(current_user).with_recent_activity.limit(5)`*
  - *Fixed Arel.sql() issue for raw SQL in order clause*
  - *Fixed horizontal scrollbar with overflow-x-hidden*
- [x] Typing indicator in chat list/dashboard
  - *New `chat_list_controller.js` Stimulus controller*
  - *Subscribes to each chat's ActionCable channel*
  - *Swaps last message preview with typing indicator*
- [x] Unread count badges
- [ ] Upcoming events widget *(placeholder - Event model not yet created)*
- [ ] Recent photos widget *(placeholder - MediaItem model not yet created)*

#### 1.12 UI Polish (Sprint 1)
- [x] Custom modal/confirmation dialog system
  - *Replaced browser confirm() dialogs*
  - *Styled modal with themed buttons*
  - *Fixed button sizing (border consistency)*
  - *Fixed focus outline (outline-offset: -2px, :focus-visible)*
- [x] Consistent button styling
  - *`.btn` base class with 1px solid transparent border*
  - *`.btn-secondary` sets border-color only*
- [x] Dashboard widget sizing
  - *All widgets use h-80 for consistent height*

---

### Sprint 2: Calendar & User Profiles (UPCOMING)

**Goal**: Implement the shared calendar and complete user profile management.

#### 2.1 User Profile Page
- [ ] Profile view page
- [ ] Edit profile form
- [ ] Avatar upload with cropping
- [ ] Change password form
- [ ] Notification preferences (checkboxes)
- [ ] Theme selection (dropdown of admin presets)
- [ ] Color mode toggle (light/dark/system)

#### 2.2 Admin Dashboard
- [x] Admin-only routes/authorization
- [x] Access requests management
- [x] User list with status management
- [x] User status toggle (active/inactive/removed)
- [x] Reset user password functionality
  - *Custom confirmation modal for password reset*
  - *Generates new temporary password*
  - *Displays password to admin after reset*

#### 2.3 Theme Management (Admin)
- [ ] Theme model and migration
- [ ] Theme palette builder UI (color pickers)
- [ ] Create/edit/delete themes
- [ ] Set default theme
- [ ] Preview theme before saving
- [ ] Seed default "Ocean Blue" theme

#### 2.4 Calendar Models
- [ ] Event model with recurrence
- [ ] EventRsvp model
- [ ] EventReminder model

#### 2.5 Calendar UI - Month View
- [ ] Monthly calendar grid
- [ ] Event display on calendar
- [ ] Navigation (prev/next month)
- [ ] Today highlight

#### 2.6 Calendar UI - Event Management
- [ ] Create event modal/form
- [ ] Edit event
- [ ] Delete event (creator + admin only)
- [ ] Recurring event support (basic: daily, weekly, monthly)

#### 2.7 RSVP System
- [ ] RSVP buttons (attending/maybe/not attending)
- [ ] RSVP list on event detail
- [ ] Real-time RSVP updates

#### 2.8 Event Reminders
- [ ] Reminder selection UI (15min, 1hr, 1day)
- [ ] Background job for sending reminders
- [ ] Reminder notifications

---

### Sprint 3: Gallery & Polish (FUTURE)

**Goal**: Complete the gallery feature and add final polish.

#### 3.1 Gallery Models
- [ ] Album model
- [ ] MediaItem model
- [ ] MediaComment model
- [ ] MediaReaction model

#### 3.2 Gallery UI - Timeline View
- [ ] Reverse chronological media feed
- [ ] Media card with uploader overlay
- [ ] Lightbox view for individual items

#### 3.3 Gallery UI - Albums
- [ ] Create album
- [ ] Album grid view
- [ ] Add media to album
- [ ] Album cover image

#### 3.4 Media Upload & Processing
- [ ] Drag-and-drop upload
- [ ] Progress indicator
- [ ] 100MB size validation
- [ ] File type detection (HEIC, MOV, MP4, etc.)
- [ ] `ProcessMediaJob` background job

#### 3.5 Image Processing
- [ ] Install libvips + image_processing gem
- [ ] HEIC/HEIF → WebP/JPEG conversion
- [ ] Balanced compression (~50-60% reduction)
- [ ] Generate variants: thumbnail (200px), medium (800px), full
- [ ] Preserve EXIF data where appropriate

#### 3.6 Video Processing
- [ ] Install FFmpeg + streamio-ffmpeg gem
- [ ] Transcode to H.264 MP4 (universal format)
- [ ] Aggressive compression (target 2-4 Mbps for 1080p)
- [ ] Cap resolution at 1080p
- [ ] Generate video thumbnail
- [ ] Handle iPhone formats (MOV, HEVC, ProRes)
- [ ] Handle Android formats (MP4, WebM, 3GP)
- [ ] Processing status indicator in UI

#### 3.7 Media Interactions
- [ ] Comments on media
- [ ] Emoji reactions
- [ ] Download media (original or processed)

---

### Sprint 4: Dashboard & Global Features (FUTURE)

#### 4.1 Dashboard Layout
- [ ] Three-column responsive layout
- [ ] Left: Chat panel (mini view)
- [ ] Center top: Calendar (mini view)
- [ ] Center bottom: Upcoming events
- [ ] Right: Gallery preview

#### 4.2 Global Search
- [ ] Search bar in navbar
- [ ] Search messages
- [ ] Search events
- [ ] Search media
- [ ] Combined results view

#### 4.3 Analytics (Admin)
- [ ] Page view tracking
- [ ] Feature usage metrics
- [ ] User activity charts
- [ ] Analytics dashboard

#### 4.4 Animations & Polish
- [ ] Page transition animations
- [ ] Micro-interactions
- [ ] Loading states
- [ ] Empty states
- [ ] Error states

---

### Sprint 5: Mobile & Advanced Features (FUTURE)

#### 5.1 Hotwire Native Setup
- [ ] iOS app shell
- [ ] Android app shell
- [ ] Bridge components for native features
- [ ] Push notification integration

#### 5.2 Enhanced Encryption
- [ ] Signal Protocol research
- [ ] Key exchange implementation
- [ ] Forward secrecy

#### 5.3 Additional Features
- [ ] User blocking
- [ ] Message search within chat
- [ ] Event categories
- [ ] Media albums sharing
- [ ] Export data feature

---

## Database Schema Summary

### Core Tables
- `users` - User accounts with authentication
- `access_requests` - Pending user registrations
- `themes` - Admin-created color themes (Sprint 2)

### Messaging Tables
- `chats` - Conversations (direct, group, public)
- `chat_memberships` - User participation in chats
- `messages` - Encrypted message content + `mentioned_user_ids` JSON
- `message_reactions` - Emoji reactions on messages
- `message_read_receipts` - Read status tracking
- `message_attachments` - File attachments (via Active Storage)
- `notifications` - Thread reply and @mention notifications (polymorphic)

### Calendar Tables (Sprint 2)
- `events` - Calendar events with recurrence
- `event_rsvps` - User attendance responses
- `event_reminders` - Scheduled reminder notifications

### Gallery Tables (Sprint 3)
- `albums` - Photo/video collections
- `media_items` - Individual media files
- `media_comments` - Comments on media
- `media_reactions` - Reactions on media

### Utility Tables
- `mentions` - @username mentions (polymorphic)
- `analytics_events` - Usage tracking

---

## File Structure

```
family-hub/
├── app/
│   ├── channels/          # ActionCable channels
│   ├── controllers/       # Request handlers
│   │   ├── admin/         # Admin-only controllers
│   │   └── concerns/      # Shared controller logic
│   ├── helpers/           # View helpers
│   ├── javascript/
│   │   ├── controllers/   # Stimulus controllers
│   │   └── channels/      # ActionCable consumers
│   ├── models/            # ActiveRecord models
│   │   └── concerns/      # Shared model logic
│   ├── services/          # Business logic services
│   ├── jobs/              # Background jobs
│   └── views/
│       ├── layouts/       # Application layouts
│       ├── shared/        # Shared partials
│       └── admin/         # Admin views
├── config/
│   ├── tailwind.config.js
│   ├── routes.rb
│   └── cable.yml
├── db/
│   ├── migrate/
│   └── seeds.rb
├── DEVELOPMENT_PLAN.md    # This file
└── test/
```

---

## Testing Checklist

### Manual Testing (Current Sprint)
- [x] Request access flow works
- [x] Admin can approve/deny with temp password
- [x] User forced to change password on first login
- [x] Chat messages appear in real-time
- [x] Typing indicators show correctly (continuous while typing)
- [x] Read receipts update properly
- [x] Emoji reactions work (300+ emojis)
- [x] Theme toggle persists (light/dark)
- [x] File uploads work (images, videos, docs)
  - *Lightbox viewer with keyboard navigation*
  - *Smart grid layout for multiple images*
- [x] All UI has 15px border radius
- [x] Animations are smooth

### Future Testing
- [ ] Calendar events can be created/edited
- [ ] RSVP works in real-time
- [ ] Gallery uploads work
- [ ] HEIC images from iPhone convert correctly
- [ ] MOV videos from iPhone transcode correctly
- [ ] Media processing status shows while processing

---

## Change Log

### Session: Initial Sprint 1 Work
**Items Completed:**
- Project setup and configuration
- Authentication system with password change flow
- Access request and approval workflow
- Core chat models and UI
- Real-time messaging with ActionCable
- Message reactions, replies, typing indicators

### Session: UI Polish & Bug Fixes
**Items Completed:**
- Custom modal/confirmation dialog system (replaced browser dialogs)
- Fixed button sizing inconsistency (border: 1px solid transparent)
- Fixed focus outline appearance (:focus-visible with outline-offset: -2px)
- Fixed Reset Password form submission (data: { turbo: false })
- Fixed SQL error in chat list (Arel.sql() wrapper)
- Expanded emoji picker to 300+ emojis with categories
- Fixed typing indicator timing (continuous 3-second intervals)
- Fixed typing indicator layout (inline above input)
- Dashboard chat widget now shows recent conversations
- Typing indicator in chat list/dashboard widget
- Fixed dashboard widget sizing (h-80 for all)
- Fixed horizontal scrollbar in chat widget (overflow-x-hidden)

**Technical Details:**
- `app/assets/tailwind/application.css` - Button and typing indicator styles
- `app/views/shared/_confirm_dialog.html.erb` - Custom modal component
- `app/models/message_reaction.rb` - QUICK_EMOJIS and EMOJI_CATEGORIES
- `app/javascript/controllers/chat_controller.js` - Continuous typing status
- `app/javascript/controllers/chat_list_controller.js` - New controller for list typing
- `app/controllers/dashboard_controller.rb` - Load recent chats with defensive coding
- `app/views/dashboard/show.html.erb` - Chat widget with typing indicator

### Session: Message Attachments
**Items Completed:**
- File attachments in chat messages (images, videos, documents)
- 100MB file size limit with validation
- File type validation (images, videos, PDFs, Word docs, text files)
- Attachment preview before sending (thumbnails for images, icons for others)
- Remove individual files before sending
- Images display inline with click-to-open
- Videos display with native HTML5 player
- Documents display with icon, filename, size, and download button

**Technical Details:**
- `app/models/message.rb` - Added constants for allowed types, validation, helper methods
- `app/javascript/controllers/attachment_controller.js` - New Stimulus controller
- `app/views/chats/_message_form.html.erb` - Added attachment button and preview area
- `app/views/messages/_message.html.erb` - Updated to display attachments
- `app/views/messages/_attachments.html.erb` - New partial for attachment rendering

### Session: Chat UX Improvements
**Items Completed:**
- Enter key sends message, Shift+Enter for new line (desktop behavior)
- Google Messages style reply preview
  - Displays replied-to message content preview above reply
  - Shows sender name with accent bar on left
  - Clickable to scroll to original message
  - Handles deleted messages, text, and attachments
  - Reply indicator while composing also shows preview

**Technical Details:**
- `app/javascript/controllers/chat_controller.js`
  - Added `handleEnter()` method for Enter/Shift+Enter behavior
  - Updated `startReply()` to populate content preview
  - Added `replyAuthor` and `replyContent` targets
- `app/views/messages/_message.html.erb`
  - Reply preview shows parent message with accent bar
  - Reply button passes content and attachment data
- `app/views/chats/show.html.erb`
  - Composing reply indicator redesigned with preview style

### Session: Lightbox & Smart Grid
**Items Completed:**
- Built-in lightbox/gallery viewer for images
  - Click image to open fullscreen overlay with smooth animation
  - Navigate through ALL images in the chat (not just current message)
  - Keyboard navigation: Left/Right arrows, Escape to close
  - Image counter showing "X of Y"
  - Caption shows sender name
- Smart image grid layout based on aspect ratios
  - Detects portrait vs landscape vs square images on load
  - 3 images with 1 portrait: portrait left (full height), 2 others stacked right
  - Optimal visual balance for mixed aspect ratios

**Technical Details:**
- `app/javascript/controllers/lightbox_controller.js` - New Stimulus controller
  - Collects all images from #messages container dynamically
  - Tracks current position and handles navigation
  - Smooth scale/opacity transitions (300ms)
  - Prevents body scroll when open
- `app/javascript/controllers/smart_grid_controller.js` - New Stimulus controller
  - Calculates aspect ratio (width/height) when images load
  - Portrait: < 0.9, Landscape: > 1.1, Square: 0.9-1.1
  - Rearranges CSS Grid layout after all images loaded
  - DOM reordering for optimal visual layout
- `app/views/chats/show.html.erb` - Added lightbox overlay HTML
  - Close button, navigation arrows, image container
  - Counter and caption display
- `app/views/messages/_attachments.html.erb` - Updated for lightbox/smart-grid
  - Images wrapped in buttons with data-lightbox-* attributes
  - Smart-grid controller manages layout

---

## Notes & Decisions

### Completed
- First admin user logic implemented (first registration becomes admin)
- Custom modal system replacing browser dialogs
- Typing indicator sends continuously while user types (every 3 seconds)
- Emoji picker expanded to 300+ emojis organized by category
- Dashboard shows real chat data with typing indicators

### Test Users (Development)

| Email | Password | Name | Role | Status |
|-------|----------|------|------|--------|
| `admin@familyhub.local` | `password123` | Admin User | admin | active |
| `test@test.org` | `password123` | Test User | member | active |
| `someone@somewhere.org` | `password123` | Some One | member | active |

> **Note**: All test users have already changed their temporary passwords (password_changed = true).

### Deferred
- Email notifications (Action Mailer setup)
- Push notifications (until mobile is built)
- Signal Protocol encryption upgrade
- Hosted database setup
- Performance optimization for chat loading (investigate N+1 queries, pagination)

### Known Issues
- Chat page load performance is slow (to be investigated in future sprint)

---

## Bugs Fixed

### Session: Signal-Style Two-Column Layout & Real-time Fixes

#### Bug: Reply preview accent bar missing for own messages
- **Symptom**: On reply previews, the blue accent bar was visible for received messages but missing for messages you sent
- **Root Cause**: `bg-theme-primary/50` was too light/transparent against the own-message background
- **Fix**: Changed accent bar to always use `bg-theme-primary` for both sent and received messages
- **Files**: `app/views/messages/_message.html.erb`

#### Bug: Real-time messages showing on wrong side (alignment)
- **Symptom**: When User A sends a message, it appeared on the RIGHT side for User B until page refresh
- **Root Cause**: `broadcast_message_created` was passing `current_user: user` (the sender) to ALL recipients, causing alignment to be calculated from sender's perspective
- **Fix**: Changed to per-user Turbo Stream channels - `turbo_stream_from @chat, current_user` and broadcast individually to each member with their own `current_user` context
- **Files**: `app/models/message.rb`, `app/views/chats/show.html.erb`, `app/views/chats/_conversation.html.erb`

#### Bug: Chat not scrolling to bottom on initial load
- **Symptom**: Chat would load showing older messages, requiring manual scroll to see recent messages
- **Root Cause**: `scrollToBottom()` executed before images finished loading, causing incorrect scroll position
- **Fix**: Added multiple scroll attempts with timeouts + `waitForImagesToLoad()` using Promise.all to wait for all images before final scroll
- **Files**: `app/javascript/controllers/chat_controller.js`

#### Bug: Received messages had fixed width instead of dynamic
- **Symptom**: Messages from other users had a fixed width, while own messages expanded based on content
- **Root Cause**: Only sent messages used `flex flex-col` container; received messages had different structure
- **Fix**: Both sent and received messages now use `flex flex-col` with `items-start`/`items-end` for alignment, plus `width: fit-content` on `.message-bubble`
- **Files**: `app/views/messages/_message.html.erb`, `app/assets/tailwind/application.css`

#### Bug: Chat not auto-scrolling when new messages received
- **Symptom**: When User B sends a message, User A's view didn't scroll down to reveal it
- **Root Cause**: Turbo Stream appends bypass the ActionCable `received` callback - the scroll code in `handleReceived()` never fired for Turbo Stream messages
- **Fix**: Added MutationObserver on `#messages` container to detect DOM additions and trigger scroll
- **Files**: `app/javascript/controllers/chat_controller.js`

#### Bug: Unread badge persisting after viewing chat
- **Symptom**: Notification badge remained visible even after clicking into and responding in the chat
- **Root Cause**: Sidebar is outside the Turbo Frame, so `mark_as_read!` updated the database but the badge DOM wasn't refreshed
- **Fix**: JavaScript now removes the badge when `setActiveChat()` is called
- **Files**: `app/views/chats/_chat_list_item.html.erb` (added `data-unread-badge`), `app/javascript/controllers/chat_list_controller.js`

#### Bug: Chat list message preview not updating in real-time
- **Symptom**: When a new message arrived, the sidebar preview didn't show the new message
- **Root Cause**: Turbo Streams only update the conversation frame; sidebar preview is outside the frame
- **Fix**: Added `ChatChannel.broadcast_message_preview()` to send preview data via ActionCable, and JavaScript handler to update sidebar DOM
- **Files**: `app/channels/chat_channel.rb`, `app/models/message.rb`, `app/javascript/controllers/chat_list_controller.js`

#### Bug: Refreshing /chats reverts to full page single chat view
- **Symptom**: After clicking a chat (two-column view), refreshing the page showed the old full-page single chat layout
- **Root Cause**: Using `chat_path(chat)` with `turbo_action: "advance"` changed URL to `/chats/123`, which routes to `show` action on refresh
- **Fix**: Changed links to use `chats_path(active_chat: chat.id)` so URL stays as `/chats?active_chat=123`, always hitting `index` action
- **Files**: `app/views/chats/_chat_list_item.html.erb`, `app/controllers/chats_controller.rb`, `app/javascript/controllers/chat_list_controller.js`

---

## Feature Additions

### Session: Signal-Style Two-Column Chat Layout

**Feature**: Refactored chat page to Signal/Slack-style two-column layout

**Implementation**:
- Left panel (320px): Scrollable list of all chats with avatars, previews, timestamps, unread badges
- Right panel: Conversation view when chat selected, empty state when not
- Mobile: Falls back to full-width chat list, navigates to standalone show page on click
- Turbo Frames for inline loading without full page refresh
- URL uses query param (`?active_chat=123`) to preserve two-column layout on refresh

**New Files Created**:
- `app/views/chats/_chat_list_item.html.erb` - Individual chat item for sidebar
- `app/views/chats/_chat_sidebar.html.erb` - Left sidebar with header and list
- `app/views/chats/_conversation_frame.html.erb` - Turbo Frame wrapper with empty state
- `app/views/chats/_conversation.html.erb` - Conversation UI (extracted from show)
- `app/views/chats/_new_chat_frame.html.erb` - New chat form for frame context

**Files Modified**:
- `app/views/chats/index.html.erb` - Two-column layout structure
- `app/controllers/chats_controller.rb` - Turbo Frame handling, active_chat param support
- `app/javascript/controllers/chat_list_controller.js` - Active state management, unread badge handling

---

### Session: @Mentions and Thread Notifications

**Items Completed:**
- Thread reply notifications (notify parent message author when someone replies)
- @Mentions system with autocomplete, parsing, notifications, and highlighting
- Notification bell in navbar with real-time badge updates
- Toast notifications for new mentions/replies

**Database Changes:**
- Created `notifications` table (user_id, actor_id, notifiable polymorphic, notification_type, read_at)
- Added `mentioned_user_ids` JSON column to messages

**New Files Created:**
- `app/models/notification.rb` - Notification model with scopes, helpers, ActionCable broadcasts
- `app/services/mention_service.rb` - Parses @FirstName mentions, stores IDs, creates notifications
- `app/services/notification_service.rb` - Creates thread reply notifications
- `app/channels/notification_channel.rb` - Real-time notification delivery per user
- `app/controllers/notifications_controller.rb` - List, mark read, mark all read endpoints
- `app/controllers/mentions_controller.rb` - Autocomplete API for chat members
- `app/javascript/controllers/mention_controller.js` - Stimulus controller for @mention autocomplete
- `app/javascript/controllers/notification_controller.js` - Stimulus controller for notification bell/badge/toast
- `app/views/shared/_notification_bell.html.erb` - Notification UI with dropdown and toast

**Files Modified:**
- `app/models/message.rb` - Added mention callbacks, `mentioned_users` method
- `app/models/user.rb` - Added notification associations, `should_receive_notification?` helper
- `app/helpers/application_helper.rb` - Added `render_message_content` helper for mention highlighting
- `app/views/messages/_message.html.erb` - Uses helper to render content with highlighted mentions
- `app/views/chats/_message_form.html.erb` - Added mention controller and autocomplete dropdown
- `app/views/shared/_navbar.html.erb` - Added notification bell
- `app/assets/tailwind/application.css` - Added `.mention` class styling
- `config/routes.rb` - Added notification and mention routes
- `config/application.rb` - Added app/services to autoload paths

**Bug Fixes:**
- Fixed Turbo Frame error when clicking chat settings gear (added `data-turbo-frame="_top"`)
- Fixed `channels/consumer` import path in `chat_channel.js` (relative → importmap path)

---

*Last updated: Sprint 1 - Messaging System (@Mentions and Thread Notifications session)*
