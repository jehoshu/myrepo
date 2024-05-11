resource "aws_instance" "import_server_ec2" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = var.subnets[0]
    vpc_security_group_ids = [var.security_group_ids]
    tags = {
        Name = "import-server-${var.environment}" 
    }
}
resource "null_resource" "get_public_certs" {
    provisioner "local-exec" {
        command = <<EOT
        touch /tmp/env.crt
        touch /tmp/aws.crt
        echo | openssl s_client -servername NAME \ -connect ${var.vault_sub_domain}.${var.private_domain_name}:443 \ | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \ > /tmp/env.crt
        touch /tmp/env.crt
        echo | openssl s_client -servername NAME \ 
        -connect ${local.kafka_brokers[0]} \ | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \ > /tmp/aws.crt
     EOT
    }
}

resource "null_resource" "modify_import_server" {
    depends_on = [ aws_instance.import_server_ec2 ]

    provisioner "file" {
        source = "script.ps1"
        destination = "C:/script.ps1"
          connection {
            type = "winrm"
            host = aws_instance.import_server_ec2.private_ip
            password = var.password
            user = "Administrator"
            https = true
            insecure = true
            timeout = "30"
    }
}

    provisioner "file" {
        source = "/tmp/env.crt"
        destination = "C:/josh/Import/prod/env.crt"
          connection {
            type = "winrm"
            host = aws_instance.import_server_ec2.private_ip
            password = var.password
            user = "Administrator"
            https = true
            insecure = true
            timeout = "30"
      
    }
}
    provisioner "remote-exec" {
          connection {
            type = "winrm"
            host = aws_instance.import_server_ec2.private_ip
            password = var.password
            user = "Administrator"
            https = true
            insecure = true
            timeout = "30"
    }
    inline = [ 
        "powershell.exe setx VAULT_ADDR $ {var.vault_sub_domain}.${var.private_domain_name}",
        "powershell.exe setx VAULT_TOKEN ${var.vault_token}",
        "powershell.exe setx SASL_MECHANISM SCRAM-SHA-512",
        "powershell.exe setx SECURITY_PROTOCOL SASL_SSL",
        "powershell.exe setx BOOTSTRAP_SERVER_URL ${local.kafka_brokers[0]}",
        "powershell.exe setx ENV_NAME ${var.environment}",
        "powershell.exe setx -Command Set-ExecutionPolicy Unrestricted -Force ",
        "powershell.exe C:/script.ps1 https://${var.private_domain_name}.${var.monitor_sub_domain}.${var.task_id}.${var.task_date}.${var.customer_name}"
     ]
    }
}

