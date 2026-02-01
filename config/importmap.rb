# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# ActionCable for real-time features
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"

# Password strength estimation (lazy loaded)
pin "zxcvbn", to: "https://cdn.jsdelivr.net/npm/zxcvbn@4.4.2/dist/zxcvbn.js"

# Color picker for theme customization
pin "coloris", to: "https://ga.jspm.io/npm:@melloware/coloris@0.24.0/dist/coloris.min.js"
pin "@melloware/coloris", to: "https://ga.jspm.io/npm:@melloware/coloris@0.24.0/dist/coloris.min.js"
