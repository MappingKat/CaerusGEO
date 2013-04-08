# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
CaerusGeo::Application.config.secret_token = (Rails.env=='test') ? "5090d0204fa4d0ca21e7599d8c23545efb7049f33cdb420ecda8ab6e9177c1bd2cf968ec7254b84c081f5c886603189107ae88264071861bd5b26a321a8fe5d1"  : ENV['SECRET']
