resource "null_resource" "cluster" {
  triggers = {
    	group_name    = var.group_name
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "./rafay_group.sh"
    environment = {
      GROUP_NAME	= var.group_name
    }

  }

 provisioner "local-exec" {
    when = destroy
    interpreter = ["/bin/bash","-c"]
    command = "./rafay_group_cleanup.sh ${self.triggers.group_name}"

  }
}

