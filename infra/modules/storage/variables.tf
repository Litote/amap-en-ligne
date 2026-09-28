variable "name" {
  description = "Naming prefix (project-env)"
  type        = string
}

variable "zip_path" {
  description = "Local path to the native GraalVM Lambda ZIP (custom runtime without RIC)"
  type        = string
}

variable "tags" {
  description = "AWS tags to apply to the resources"
  type        = map(string)
  default     = {}
}
