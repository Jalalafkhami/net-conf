install: install_packages make_executable
	echo "ّٔInitial Installation complete. Please Run 'sudo ./main.sh'"

# installing Requirement Package
install_packages:
	@echo "Installing packages..."
	@if [ -f /etc/debian_version ]; then \
		sudo apt-get update && sudo apt-get install -y dialog openvswitch-switch nftables; \
	elif [ -f /etc/redhat-release ]; then \
		sudo yum install -y dialog openvswitch-switch nftables; \
	else \
		echo "Unsupported Linux distribution. Please install packages manually."; \
		exit 1; \
	fi

# Change mod all scripts to executable
make_executable:
	@echo "Making all .sh scripts executable..."
	find . -type f -name "*.sh" -exec sudo chmod +x {} \;

