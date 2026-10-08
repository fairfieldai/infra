ENV ?= global
DIR = environments/$(ENV)

.PHONY: init fmt reconfigure validate lint plan apply refresh destroy discord-plan discord-apply discord-check

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

# Discord server setup (scripts/discord). The bot needs the Administrator
# permission while these run, even for discord-plan.
DISCORD = cd scripts/discord && uv run --locked

discord-plan:
	$(DISCORD) python discord_setup.py --dry-run

discord-apply:
	$(DISCORD) python discord_setup.py

discord-check:
	$(DISCORD) ruff format --check
	$(DISCORD) ruff check
	$(DISCORD) ty check
	$(DISCORD) pytest -q
