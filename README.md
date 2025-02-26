# Sec-deploy
------------
a security deploy on huawei cloud using terraform

## Steps
------------
1. Install Terraform
2. Add the oficial provider
3. Obtain Active and Secret Key (AK/SK)
4. Resoources are deploy to the cloud

## Requirements
------------
* Terraform: https://www.terraform.io
* Huawei provider: https://github.com/huaweicloud/terraform-provider-huaweicloud

## Instructions
------------
* Obtain a AK/SK from the Huawei Cloud console in [MyCredentials](https://console-intl.huaweicloud.com/iam/#/mine/apiCredential) page 
* Add your AK/SK data and region to the **terraform.tfvars** terraform file
* Don't forget initialize your environment with: `terraform init`
* Apply the script into the cloud using: `terraform apply`
