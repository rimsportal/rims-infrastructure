variable "application_name_prefix" {
  description = "Prefix used for the Supervisor and Worker mobile app registration display names."
  type        = string
}

variable "environment" {
  description = "Short deployment environment name appended to each mobile registration."
  type        = string
}

variable "api_client_id" {
  description = "Client ID of the existing DT Factory API application registration."
  type        = string
}

variable "api_application_object_id" {
  description = "Object ID of the existing DT Factory API application registration."
  type        = string
}

variable "api_access_scope_id" {
  description = "ID of the access_as_user delegated permission exposed by the DT Factory API."
  type        = string
}

variable "public_redirect_uris" {
  description = "Temporary public-client redirect URIs used until Android package and iOS bundle metadata is available."
  type        = set(string)
}
