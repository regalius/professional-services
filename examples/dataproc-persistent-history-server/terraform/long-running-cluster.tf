/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_dataproc_cluster" "long-running-cluster" {
  depends_on = ["google_storage_bucket.history-bucket",
    "google_storage_bucket_object.spark-events-dir",
    "google_storage_bucket_object.disable-history-servers-init-action",
  ]

  project = "${var.project}"
  name    = "${var.long-running-cluster}"
  region  = "${var.history-region}"

  cluster_config {
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-1"

      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 50
      }
    }

    worker_config {
      num_instances = 2
      machine_type  = "n1-standard-1"

      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 500
      }
    }

    software_config {
      image_version = "1.4.0-debian9"

      override_properties = {
        "yarn:log-aggregation-enable"                       = "true"
        "yarn:nodemanager.remote-app-log-dir"               = "gs://${var.history-bucket}/yarn/logs/"
        "yarn:log-aggregation.retain-seconds"               = "-1"
        "mapred:mapreduce.jobhistory.done-dir"              = "gs://${var.history-bucket}/done-dir"
        "mapred:mapreduce.jobhistory.intermediate-done-dir" = "gs://${var.history-bucket}/intermediate-done-dir"
        "spark:spark.eventLog.dir"                          = "gs://${var.history-bucket}/spark-events/"
        "spark:spark.history.fs.logDirectory"               = "gs://${var.history-bucket}/spark-events/"
      }
    }

    initialization_action = {
      script = "gs://${var.history-bucket}/init_actions/disable_history_servers.sh"
    }

    gce_cluster_config {
      subnetwork       = "${module.vpc.subnets_names[0]}"
      internal_ip_only = true
      tags             = ["hadoop-history-ui-access"]
    }
  }
}
