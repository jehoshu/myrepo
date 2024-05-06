Enable Grafana Loki


Loki:

Grafana Loki is a logging platform that utilizes Prometheus-inspired labels to store, query,and visualize logs efficiently.
With S3 as a backend, Loki stores log data in object storage, providing cost-effective, 
durable, and scalable storage for logs, enabling long-term retention and seamless integration with Grafana for visualization and analysis.

Promtail:

Promtail typically runs as a DaemonSet in Kubernetes, ensuring that an instance of the agent is deployed on each node in the cluster. This setup allows for efficient log collection across all nodes. Resource configurations such as CPU and memory can be specified to ensure optimal performance and resource utilization.

Grafana:

Grafana provides a unified platform for viewing dashboards that combine both metrics and logs data. With integrations for Prometheus for metrics and Loki for logs, Grafana enables users to visualize and correlate data from both sources, facilitating comprehensive monitoring, troubleshooting, and analysis of systems and applications


Upgrade Deployment Steps:
1. Update tf-version.yaml:
   k8s-istio-internal-ingress: 1.2.3
   k8s-prometheus-operator: 3.3.3
2. Update env.hcl:
  monitoring = {
    loki_enabled         = true
    grafana_enabled      = true
    remote_write_enabled = true
    region               = local.aws_region
    }
3. Add to Prometheus.hcl this inputs:
  customer_id                      = local.environment_vars.locals.customer_id
  loki_enabled                     = local.environment_vars.locals.monitoring.loki_enabled
  grafana_enabled                  = local.environment_vars.locals.monitoring.grafana_enabled
  remote_write                     = local.environment_vars.locals.monitoring.remote_write_enabled
  region                           = local.environment_vars.locals.monitoring.region 
4. Apply terragrunt- prometheus module

Grafana access:

URL: https://grafana-production.test.josh.com
User: admin
Password: admin

1. Access Loki UI
2. Go to the 3 dashes at the top left and select "explore"
3. Select DS loki