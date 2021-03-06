terraform {
  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.14"
}
