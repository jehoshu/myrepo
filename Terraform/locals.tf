locals {
  kafka_brokers = split(",", var.kafka_bootstrap_servers)
}