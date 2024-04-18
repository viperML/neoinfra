{ config, pkgs, ... }:
{
  # https://github.com/mautrix/whatsapp/blob/v0.10.6/example-config.yaml
  services.mautrix-whatsapp.settings = {
    homeserver = {
      address = "http://localhost:8008";
      domain = "matrix.ayats.org";
      software = "standard";
      status_endpoint = null;
      message_send_checkpoint_endpoint = null;
      async_media = false;
      websocket = false;
      ping_interval_seconds = 0;
    };
    appservice = {
      address = "http://localhost:29318";
      hostname = "0.0.0.0";
      port = 29318;
      database = {
        type = "postgres";
        uri = "postgresql:///mautrix_whatsapp?host=/run/postgresql";
        max_open_conns = 20;
        max_idle_conns = 2;
        max_conn_idle_time = null;
        max_conn_lifetime = null;
      };
      id = "whatsapp";
      bot = {
        username = "whatsappbot";
        displayname = "WhatsApp bridge bot";
        avatar = "mxc://maunium.net/NeXNQarUbrlYBiPCpprYsRqr";
      };
      ephemeral_events = true;
      async_transactions = false;
      as_token = "";
      hs_token = "";
    };
    analytics = {
      host = "api.segment.io";
      token = null;
      user_id = null;
    };
    metrics = {
      enabled = false;
      listen = "127.0.0.1:8001";
    };
    whatsapp = {
      os_name = "Mautrix-WhatsApp bridge";
      browser_name = "unknown";
    };
    bridge = {
      username_template = "whatsapp_{{.}}";
      displayname_template = "{{or .BusinessName .PushName .JID}} (WA)";
      personal_filtering_spaces = false;
      delivery_receipts = false;
      message_status_events = false;
      message_error_notices = true;
      call_start_notices = true;
      identity_change_notices = false;
      portal_message_buffer = 128;
      # https://docs.mau.fi/bridges/general/backfill.html
      history_sync = {
        backfill = true;
        max_initial_conversations = -1;
        message_count = 50;
        request_full_sync = false;
        full_sync_config = {
          days_limit = null;
          size_mb_limit = null;
          storage_quota_mb = null;
        };
        unread_hours_threshold = 0;
        media_requests = {
          auto_request_media = true;
          request_method = "immediate";
          request_local_time = 120;
        };
        immediate = {
          worker_count = 1;
          max_events = 10;
        };
        deferred = [
          {
            start_days_ago = 7;
            max_batch_events = 20;
            batch_delay = 5;
          }
          {
            start_days_ago = 30;
            max_batch_events = 50;
            batch_delay = 10;
          }
          {
            start_days_ago = 90;
            max_batch_events = 100;
            batch_delay = 10;
          }
          {
            start_days_ago = -1;
            max_batch_events = 500;
            batch_delay = 10;
          }
        ];
      };
      user_avatar_sync = true;
      bridge_matrix_leave = true;
      sync_direct_chat_list = false;
      sync_manual_marked_unread = true;
      default_bridge_presence = true;
      send_presence_on_typing = false;
      force_active_delivery_receipts = false;
      double_puppet_server_map = {
        "example.com" = "https://example.com";
      };
      double_puppet_allow_discovery = false;
      login_shared_secret_map = {
        "example.com" = "foobar";
      };
      private_chat_portal_meta = "default";
      parallel_member_sync = false;
      bridge_notices = true;
      resend_bridge_info = false;
      mute_bridging = false;
      archive_tag = null;
      pinned_tag = null;
      tag_only_on_create = true;
      enable_status_broadcast = true;
      disable_status_broadcast_send = true;
      mute_status_broadcast = true;
      status_broadcast_tag = "m.lowpriority";
      whatsapp_thumbnail = false;
      allow_user_invite = false;
      federate_rooms = true;
      disable_bridge_alerts = false;
      crash_on_stream_replaced = false;
      url_previews = false;
      caption_in_message = false;
      beeper_galleries = false;
      extev_polls = false;
      cross_room_replies = false;
      disable_reply_fallbacks = false;
      message_handling_timeout = {
        error_after = null;
        deadline = "120s";
      };
      command_prefix = "!wa";
      management_room_text = {
        welcome = "Hello, I'm a WhatsApp bridge bot.";
        welcome_connected = "Use `help` for help.";
        welcome_unconnected = "Use `help` for help or `login` to log in.";
        additional_help = "";
      };
      # https://docs.mau.fi/bridges/general/end-to-bridge-encryption.html
      encryption = {
        allow = true;
        default = true;
        appservice = false;
        require = true;
        allow_key_sharing = false;
        plaintext_mentions = false;
        delete_keys = {
          delete_outbound_on_ack = false;
          #
          dont_store_outbound = true;
          ratchet_on_decrypt = true;
          delete_fully_used_on_decrypt = true;
          delete_prev_on_new_session = true;
          delete_on_device_delete = true;
          periodically_delete_expired = true;
          delete_outdated_inbound = true;
        };
        verification_levels = {
          receive = "cross-signed-tofu";
          send = "cross-signed-tofu";
          share = "cross-signed-tofu";
        };
        rotation = {
          enable_custom = false;
          milliseconds = 604800000;
          messages = 100;
          disable_device_change_key_rotation = false;
        };
      };
      provisioning = {
        prefix = "/_matrix/provision";
        shared_secret = "generate";
        debug_endpoints = false;
      };
      permissions = {
        "*" = "relay";
        "example.com" = "user";
        "@admin:example.com" = "admin";
      };
      relay = {
        enabled = false;
        admin_only = true;
        message_formats = {
          "m.text" = "<b>{{ .Sender.Displayname }}</b>: {{ .Message }}";
          "m.notice" = "<b>{{ .Sender.Displayname }}</b>: {{ .Message }}";
          "m.emote" = "* <b>{{ .Sender.Displayname }}</b> {{ .Message }}";
          "m.file" = "<b>{{ .Sender.Displayname }}</b> sent a file";
          "m.image" = "<b>{{ .Sender.Displayname }}</b> sent an image";
          "m.audio" = "<b>{{ .Sender.Displayname }}</b> sent an audio file";
          "m.video" = "<b>{{ .Sender.Displayname }}</b> sent a video";
          "m.location" = "<b>{{ .Sender.Displayname }}</b> sent a location";
        };
      };
    };
    logging = {
      min_level = "debug";
      writers = [
        {
          type = "stdout";
          format = "pretty-colored";
        }
        # {
        #   type = "file";
        #   format = "json";
        #   filename = "./logs/mautrix-whatsapp.log";
        #   max_size = 100;
        #   max_backups = 10;
        #   compress = true;
        # }
      ];
    };
  };
}
