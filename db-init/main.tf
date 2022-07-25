resource "kubernetes_namespace" "db" {
  count = local.pod_config.namespace_create ? 1 : 0
  metadata {
    annotations = {
      optimized-by-cce = true
    }
    name = local.pod_config.namespace
  }
}

resource "kubernetes_pod" "database_init" {
  metadata {
    name        = local.pod_config.name
    namespace   = local.pod_config.namespace
    annotations = local.pod_config.annotations
    labels      = local.pod_config.labels
  }
  spec {
    container {
      name    = local.pod_config.name
      image   = "alpine:3.12"
      command = ["/bin/sh", "-c"]
      args = [join(" ", [
        "apk add --no-cache ${local.db_engines[var.database_engine].client} &&",
        "${local.db_engines[var.database_engine].command} <<-EOSQL\n${var.initdb_script}\nEOSQL\n",
        "sleep 30",
      ])]
      dynamic "env" {
        for_each = local.db_engines[var.database_engine].env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
    restart_policy = "Never"
  }
  lifecycle {
    ignore_changes = [
      metadata[0],
      spec[0].dns_config,
      spec[0].node_selector,
      spec[0].container[0].image,
      spec[0].container[0].volume_mount,
    ]
  }
}
