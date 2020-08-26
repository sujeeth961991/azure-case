variable "group_members" {
  description = "List of member ids to be added as group members"
  type        = list(string)
}
variable "group_name" {
  description = "Name for the Azure Active Directory Group"
  type        = string
}