resource "google_compute_http_health_check" "puma-http-hc" {
  name         = "puma-http-health-check"
  request_path = "/"
  port         = "9292"

  timeout_sec        = 1
  check_interval_sec = 1
}

resource "google_compute_target_pool" "puma-target-pool" {
  name = "instance-pool"

  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]

  health_checks = [
    "${google_compute_http_health_check.puma-http-hc.self_link}",
  ]
}

resource "google_compute_forwarding_rule" "puma-lb-forwarding-rule" {
  name                  = "puma-lb-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  target                = "${google_compute_target_pool.puma-target-pool.self_link}"
}
