
0) Change parameters in backend/dev.backend.tfvars and envs/dev.tfvars

1) init
terraform init -upgrade -backend-config=backend/dev.backend.tfvars

2) Create secret from module.secret_manager 
terraform apply --target=module.secret_manager --auto-approve -var-file=envs/dev.tfvars


3) apply
terraform apply --auto-approve -var-file=envs/dev.tfvars


4) Check

5) destroy
terraform destroy --auto-approve -var-file=envs/dev.tfvars
