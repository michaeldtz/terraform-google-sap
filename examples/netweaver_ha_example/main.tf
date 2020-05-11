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

provider "google" {
  version = "~> 3.13.0"
}

module "gcp_netweaver" {
  source                 = "../../modules/netweaver_ha"
  post_deployment_script = var.post_deployment_script
  subnetwork             = var.subnetwork
  linux_image_family     = var.linux_image_family
  linux_image_project    = var.linux_image_project
  autodelete_disk        = "true"
  public_ip              = var.public_ip
  sap_deployment_debug   = var.sap_deployment_debug
  usr_sap_size           = var.usr_sap_size
  sap_mnt_size           = var.sap_mnt_size
  swap_size              = var.swap_size
  
  instance_type          = var.instance_type
  region                 = var.region
  network_tags           = var.network_tags
  project_id             = var.project_id
  
  service_account_email  = var.service_account_email
  boot_disk_size         = var.boot_disk_size
  boot_disk_type         = var.boot_disk_type
  disk_type              = var.disk_type
  
  primary_instance_name      = var.primary_instance_name
  secondary_instance_name    = var.secondary_instance_name
  primary_zone               = var.primary_zone
  secondary_zone             = var.secondary_zone
  primary_instance_ip        = var.primary_instance_ip
  secondary_instance_ip      = var.secondary_instance_ip

  sap_vip                    = var.sap_vip
  sap_vip_internal_address   = var.sap_vip_internal_address
  sap_vip_secondary_range    = var.sap_vip_secondary_range
  
  startup_script_1           = file(var.startup_script_1)
  startup_script_2           = file(var.startup_script_2)
  
  pd_kms_key             = google_kms_crypto_key.netweaver_simple.self_link

}

# Create a KMS key to use as customer managed encryption key for the instance
# persistent disk. This is completely optional. If you do not need to manage
# your own keys, just remove this section and remove also the pd_kms_key
# parameter in the module declaration above.
resource "google_kms_key_ring" "netweaver_simple" {
  project  = var.project_id
  name     = "netweaver-simple-${random_id.this.hex}"
  location = var.region
}

resource "google_kms_crypto_key" "netweaver_simple" {
  name     = "netweaver-simple-${random_id.this.hex}"
  key_ring = google_kms_key_ring.netweaver_simple.self_link
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "netweaver_simple" {
  crypto_key_id = google_kms_crypto_key.netweaver_simple.self_link
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}

resource "random_id" "this" {
  byte_length = 2
}
