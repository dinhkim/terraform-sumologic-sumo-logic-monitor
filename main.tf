locals {
  # Logs Monitor
  LogsCriticalAlert = [for d in var.triggers: d if d.trigger_type =="Critical" && var.monitor_monitor_type == "Logs"]
  LogsResolveCriticalAlert = [for d in var.triggers: d if d.trigger_type =="ResolvedCritical" && var.monitor_monitor_type == "Logs"]
  LogsWarningAlert = [for d in var.triggers: d if d.trigger_type =="Warning" && var.monitor_monitor_type == "Logs"]
  LogsResolveWarningAlert = [for d in var.triggers: d if d.trigger_type =="ResolvedWarning" && var.monitor_monitor_type == "Logs"]
  LogsMissingData = [for d in var.triggers: d if d.trigger_type =="MissingData" && var.monitor_monitor_type == "Logs"]

  # Metrics Monitor
  MetricsCriticalAlert = [for d in var.triggers: d if d.trigger_type =="Critical" && var.monitor_monitor_type == "Metrics"]
  MetricsResolveCriticalAlert = [for d in var.triggers: d if d.trigger_type =="ResolvedCritical" && var.monitor_monitor_type == "Metrics"]
  MetricsWarningAlert = [for d in var.triggers: d if d.trigger_type =="Warning" && var.monitor_monitor_type == "Metrics"]
  MetricsResolveWarningAlert = [for d in var.triggers: d if d.trigger_type =="ResolvedWarning" && var.monitor_monitor_type == "Metrics"]
  MetricsMissingData = [for d in var.triggers: d if d.trigger_type =="MissingData" && var.monitor_monitor_type == "Metrics"]

  hasLogsCriticalAlert = (length(local.LogsCriticalAlert) + length(local.LogsResolveCriticalAlert)) == 2
  hasLogsWarningAlert = (length(local.LogsWarningAlert) + length(local.LogsResolveWarningAlert)) == 2
  hasMetricsCriticalAlert = (length(local.MetricsCriticalAlert) + length(local.MetricsResolveCriticalAlert)) == 2
  hasMetricsWarningAlert = (length(local.MetricsWarningAlert)+ length(local.MetricsResolveWarningAlert)) == 2
  hasLogsMissingData = length(local.LogsMissingData) == 1
  hasMetricsMissingData = length(local.MetricsMissingData) == 1
}

resource "sumologic_monitor" "tf_monitor" {
  name = var.monitor_name
  parent_id  = var.monitor_parent_id
  description = var.monitor_description
  type = "MonitorsLibraryMonitor"
  is_disabled = var.monitor_is_disabled
  content_type = "Monitor"
  monitor_type = var.monitor_monitor_type
  group_notifications = var.group_notifications

  dynamic "queries" {
      for_each = var.queries
      content {
            row_id = queries.key
            query = queries.value
      }
  }

 trigger_conditions {
    dynamic "logs_static_condition" {
            for_each = toset(var.monitor_monitor_type == "Logs" ? ["1"] : [])
            content {
              dynamic "critical" {
                for_each = local.hasLogsCriticalAlert ? ["1"] : []
                content {
                      time_range = local.LogsCriticalAlert[0].time_range
                      alert {
                        threshold      = local.LogsCriticalAlert[0].threshold
                        threshold_type = local.LogsCriticalAlert[0].threshold_type
                      }
                      resolution {
                        threshold      = local.LogsResolveCriticalAlert[0].threshold
                        threshold_type = local.LogsResolveCriticalAlert[0].threshold_type
                      }
                    }
              }
              dynamic "warning" {
                for_each = local.hasLogsWarningAlert ? ["1"] : []
                content {
                  time_range = local.LogsWarningAlert[0].time_range
                  alert {
                    threshold      = local.LogsWarningAlert[0].threshold
                    threshold_type = local.LogsWarningAlert[0].threshold_type
                  }
                  resolution {
                    threshold      = local.LogsResolveWarningAlert[0].threshold
                    threshold_type = local.LogsResolveWarningAlert[0].threshold_type
                  }
                }
              }
            }
    }
    dynamic "logs_missing_data_condition" {
      for_each = local.hasLogsMissingData ? ["1"] : []
      content {
        time_range = local.LogsMissingData[0].time_range
      }
    }
    dynamic "metrics_static_condition" {
            for_each = toset(var.monitor_monitor_type == "Metrics" ? ["1"] : [])
            content {
              dynamic "critical" {
                for_each = local.hasMetricsCriticalAlert ? ["1"] : []
                content {
                      time_range = local.MetricsCriticalAlert[0].time_range
                      occurrence_type = local.MetricsCriticalAlert[0].occurrence_type
                      alert {
                        threshold      = local.MetricsCriticalAlert[0].threshold
                        threshold_type = local.MetricsCriticalAlert[0].threshold_type
                      }
                      resolution {
                        threshold      = local.MetricsResolveCriticalAlert[0].threshold
                        threshold_type = local.MetricsResolveCriticalAlert[0].threshold_type
                      }
                    }
              }
              dynamic "warning" {
                for_each = local.hasMetricsWarningAlert ? ["1"] : []
                content {
                  time_range = local.MetricsWarningAlert[0].time_range
                  occurrence_type = local.MetricsWarningAlert[0].occurrence_type
                  alert {
                    threshold      = local.MetricsWarningAlert[0].threshold
                    threshold_type = local.MetricsWarningAlert[0].threshold_type
                  }
                  resolution {
                    threshold      = local.MetricsResolveWarningAlert[0].threshold
                    threshold_type = local.MetricsResolveWarningAlert[0].threshold_type
                  }
                }
              }
            }
    }
    dynamic "metrics_missing_data_condition" {
      for_each = local.hasMetricsMissingData ? ["1"] : []
      content {
        time_range = local.MetricsMissingData[0].time_range
        trigger_source = local.MetricsMissingData[0].trigger_source
      }
    }
  }

  dynamic "notifications" {
    for_each = var.connection_notifications
            content {
                run_for_trigger_types = notifications.value.run_for_trigger_types
              notification {
                connection_type = notifications.value.connection_type
                connection_id = notifications.value.connection_id
                payload_override = notifications.value.payload_override
            }
          }
  }

  dynamic "notifications" {
    for_each = var.email_notifications
            content {
                run_for_trigger_types = notifications.value.run_for_trigger_types
              notification {
                connection_type = notifications.value.connection_type
                recipients = notifications.value.recipients
                subject = notifications.value.subject
                time_zone = notifications.value.time_zone
                message_body = notifications.value.message_body
            }
          }
  }
}
