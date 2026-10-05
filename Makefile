ENV ?= global
DIR = environments/$(ENV)

.PHONY: init fmt reconfigure validate lint plan apply refresh destroy

init:
	cd $(DIR) && terraform init -upgrade

reconfigure:
	cd $(DIR) && terraform init -reconfigure

fmt:
	terraform fmt -recursive

validate: fmt
	cd $(DIR) && terraform validate

lint:
	tflint --init
	tflint --recursive --config $(CURDIR)/.tflint.hcl

plan: validate
	cd $(DIR) && terraform plan

apply:
	cd $(DIR) && terraform apply

refresh:
	cd $(DIR) && terraform refresh

destroy:
	cd $(DIR) && terraform destroy
