.PHONY: install install_packages make_executable running_service

install: install_packages make_executable running_service
	echo "Initial Installation complete. Please Run 'sudo ./main.sh'"

# installing Requirement Package
install_packages:
	@echo "Installing packages..."
	@if [ -f /etc/debian_version ]; then \
		sudo apt-get update && sudo apt-get install -y dialog openvswitch-switch nftables resolvconf; \
	elif [ -f /etc/redhat-release ]; then \
		sudo yum install -y dialog openvswitch-switch nftables resolvconf; \
	else \
		echo "Unsupported Linux distribution. Please install packages manually."; \
		exit 1; \
	fi

# Change mod all scripts to executable
make_executable:
	@echo "Making all .sh scripts executable..."
	find . -type f -name "*.sh" -exec chmod +x {} \;

# Run Services
running_service:
	@echo "Running needed services..."
	@if systemctl list-units --type=service | grep -q "resolvconf.service"; then \
		sudo systemctl enable resolvconf && sudo systemctl start resolvconf; \
	else \
		echo "resolvconf service not found."; \
	fi
	@if systemctl list-units --type=service | grep -q "nftables.service"; then \
		sudo systemctl enable nftables && sudo systemctl start nftables; \
	else \
		echo "nftables service not found."; \
	fi
