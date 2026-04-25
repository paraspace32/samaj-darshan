module FirebaseHelper
  def firebase_js_config_json
    creds = Rails.application.credentials.firebase || {}
    {
      apiKey:            creds[:api_key]            || ENV["FIREBASE_API_KEY"],
      authDomain:        creds[:auth_domain]         || ENV["FIREBASE_AUTH_DOMAIN"],
      projectId:         creds[:project_id]          || ENV["FIREBASE_PROJECT_ID"],
      storageBucket:     creds[:storage_bucket]      || ENV["FIREBASE_STORAGE_BUCKET"],
      messagingSenderId: creds[:messaging_sender_id] || ENV["FIREBASE_MESSAGING_SENDER_ID"],
      appId:             creds[:app_id]              || ENV["FIREBASE_APP_ID"]
    }.to_json
  end

  def firebase_vapid_key
    Rails.application.credentials.dig(:firebase, :vapid_key) || ENV["FIREBASE_VAPID_KEY"]
  end

  def firebase_configured?
    firebase_vapid_key.present?
  end
end
