# Terraform

You will need to create a keypair:
install ssh

ssh-keygen -t rsa -b 2048 

give it a file name and you will get two file, public and private keys


    Purple (private key)
    Purple.pub (public key)

open up the public key and copy and past it into terraform where it says public key, make sure to copy the name and replace the key_name too

# key pair
resource "aws_key_pair" "defualt" {
  key_name   = "Purple"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADQABAAABAQC+O6x7paobDWt4cilQqqU3GiasCNX+eLtJG2Ggaql0LVywT/Uh017XGJ2xuJZEjOqmjpSWLdV3uuQWXsfVgWN3Y2MbHOc5mWq1+OXUGA3mENnDndQG1mVdpx110ogh0zcrDNrdZERkvRb5TgvKxp9/UXD4uL3o9qGM/o0tgfjtRsfM4Tzec4+OXZacMtDn1SaLi5IiFMTdryZw2Vh9SwzlmIYfRMI5uZsFtXN82eujsbazivsVAyGCk76wDfwCc32i2wGqqNtQonZ3qA4bC+NmR4oa1Se+1Jhv3dS4b9k1GBfXPmvn8vjbkhbJquQLiVOIwIGtaQWR+3hL/vz5jpl speed@speed-GE60-2PC"
}

run
chmod 400 Purple


You will be able to connect to it via (replace with public IP

ssh -i "Purple" ec2-user@10.0.1.211
