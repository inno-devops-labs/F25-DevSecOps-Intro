package main

deny contains msg if {
  s := input.services[_]
  s.privileged == true
  msg := "compose service must not be privileged"
}
