#!/usr/bin/env nu

module mymod {
  use std log

  export def foo [] {
    log info "hello world"
  }
}

def "main clean" [] {
  rm -rtf .terraform
  rm -tf .terrafirn.lock.hcl
}

def "main oci-login" [] {
  oci session authenticate --region eu-marseille-1 --profile-name DEFAULT
}

use mymod

def main [] {
  ^($env.CURRENT_FILE) --help
  # mymod foo
}