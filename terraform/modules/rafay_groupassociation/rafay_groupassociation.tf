resource "null_resource" "cluster" {
  triggers = {
    	project_name  = var.project_name
    	group_name    = var.group_name
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "./rafay_groupassociation.sh"
    environment = {
      PROJECT_NAME      = var.project_name
      GROUP_NAME	= var.group_name
      ROLES		= var.roles
    }
  }

 provisioner "local-exec" {
    when = destroy
    interpreter = ["/bin/bash","-c"]
    command = "./rafay_groupassociation_cleanup.sh ${self.triggers.group_name} ${self.triggers.project_name}"

  }
}
