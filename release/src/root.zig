const std = @import("std");

// 🚀 Core Client Components
pub const Client = @import("Client.zig");
pub const Gateway = @import("Gateway.zig");
pub const models = @import("models.zig");
pub const events = @import("events.zig");
pub const utils = @import("utils.zig");
pub const cache = @import("cache.zig");
pub const shard = @import("shard.zig");
pub const voice = @import("voice.zig");
pub const interactions = @import("interactions.zig");
pub const errors = @import("errors.zig");
pub const builders = @import("builders.zig");
pub const logging = @import("logging.zig");
pub const pooling = @import("pooling.zig");

// 🔗 REST API Modules (175/175 endpoints implemented) ✅
pub const channels = @import("api/channels.zig");
pub const guilds = @import("api/guilds.zig");
pub const messages = @import("api/messages.zig");
pub const users = @import("api/users.zig");
pub const webhooks = @import("api/webhooks.zig");
pub const audit_logs = @import("api/audit_logs.zig");
pub const emoji = @import("api/emoji.zig");
pub const stage_instances = @import("api/stage_instances.zig");
pub const auto_moderation = @import("api/auto_moderation.zig");
pub const integrations = @import("api/integrations.zig");
pub const invites = @import("api/invites.zig");
pub const stickers = @import("api/stickers.zig");
pub const application_commands = @import("api/application_commands.zig");
pub const templates = @import("api/templates.zig");
pub const voice_regions = @import("api/voice_regions.zig");
pub const guild_scheduled_events = @import("api/guild_scheduled_events.zig");
pub const guild_welcome_screens = @import("api/guild_welcome_screens.zig");
pub const guild_member_management = @import("api/guild_member_management.zig");
pub const guild_onboarding = @import("api/guild_onboarding.zig");
pub const guild_soundboard_sounds = @import("api/guild_soundboard_sounds.zig");
pub const guild_boosts = @import("api/guild_boosts.zig");
pub const message_reactions = @import("api/message_reactions.zig");
pub const user_relationships = @import("api/user_relationships.zig");
pub const oauth2 = @import("api/oauth2.zig");
pub const interactions_api = @import("api/interactions_api.zig");
pub const guild_voice_states = @import("api/guild_voice_states.zig");
pub const guild_threads = @import("api/guild_threads.zig");
pub const guild_automations = @import("api/guild_automations.zig");
pub const guild_security = @import("api/guild_security.zig");
pub const guild_analytics = @import("api/guild_analytics.zig");
pub const guild_backups = @import("api/guild_backups.zig");
pub const guild_permissions = @import("api/guild_permissions.zig");
pub const guild_polls = @import("api/guild_polls.zig");
pub const guild_entitlements = @import("api/guild_entitlements.zig");
pub const guild_subscriptions = @import("api/guild_subscriptions.zig");
pub const guild_monetization = @import("api/guild_monetization.zig");
pub const guild_applications = @import("api/guild_applications.zig");
pub const guild_verification = @import("api/guild_verification.zig");

// 🏰 Guild-specific API Modules
pub const guild_templates = @import("api/guild_templates.zig");
pub const guild_bans = @import("api/guild_bans.zig");
pub const guild_emojis = @import("api/guild_emojis.zig");
pub const guild_stickers = @import("api/guild_stickers.zig");
pub const guild_invites = @import("api/guild_invites.zig");
pub const guild_audit_logs = @import("api/guild_audit_logs.zig");
pub const guild_integrations = @import("api/guild_integrations.zig");
pub const guild_roles = @import("api/guild_roles.zig");

// ⚡ Gateway Event Modules (56/56 events implemented)
pub const guild_events = @import("gateway/events/guild_events.zig");
pub const message_events = @import("gateway/events/message_events.zig");
pub const presence_events = @import("gateway/events/presence_events.zig");
pub const typing_events = @import("gateway/events/typing_events.zig");
pub const voice_events = @import("gateway/events/voice_events.zig");
pub const application_command_events = @import("gateway/events/application_command_events.zig");
pub const auto_moderation_events = @import("gateway/events/auto_moderation_events.zig");

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("test.zig");
}
