resource "null_resource" "cluster" {
  triggers = {
    	project_name  = var.project_name
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_project.sh"
    environment = {
      PROJECT_NAME      = var.project_name
    }
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_project_cleanup.sh ${self.triggers.project_name}"
  }
}

