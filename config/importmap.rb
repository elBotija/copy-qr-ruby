# Pin npm packages by running ./bin/importmap

pin "application"
pin "bootstrap", to: "bootstrap.bundle.min.js", preload: true # @5.3.3
pin "@popperjs/core", to: "bootstrap.bundle.min.js", preload: true # @2.11.8
pin "@hotwired/turbo-rails", to: "turbo.min.js" # @2.0.11
