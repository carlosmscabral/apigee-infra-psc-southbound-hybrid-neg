/**
 * Copyright 2023 Google LLC
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

variable "project_id" {
  description = "GCP Project id."
  type        = string
}

variable "region" {
  description = "Region for LB"
  type        = string
}

variable "zone" {
  description = "Zone for NEG"
  type        = string
}

variable "vpc_id" {
  description = "Id VPC to create LB/PSC NEG on"
  type        = string
}

variable "subnet-psc-attachment" {
  description = "CIDR for PSC NAT Subnet"
  type        = string
}

variable "subnet-for-fr" {
  description = "Id for existing subnet for forwarding rule"
  type        = string
}

variable "dest_ip_address" {
  description = "On-prem service destination IP address."
  type        = string
}

variable "dest_port" {
  description = "On-prem service destination port."
  type        = string
  default     = "80"
}
