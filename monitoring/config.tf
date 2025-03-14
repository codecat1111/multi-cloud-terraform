# AWS CloudWatch Monitoring
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-ec2-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# Azure Monitor
resource "azurerm_monitor_metric_alert" "vm_cpu" {
  name                = "${var.project_name}-vm-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_linux_virtual_machine_scale_set.web.id]
  description         = "Action will be triggered when CPU usage is greater than 80%"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# GCP Monitoring
resource "google_monitoring_alert_policy" "vm_cpu" {
  display_name = "${var.project_name}-vm-cpu-alert"
  combiner     = "OR"
  conditions {
    display_name = "VM CPU Usage"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.basic.id]
}