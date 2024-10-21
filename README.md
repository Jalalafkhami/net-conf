# Network Configuration Tool (NCT)

A terminal-based user interface (TUI) application for managing and configuring network settings in Linux. This tool simplifies the process of network management, firewall configuration, Open vSwitch (OVS) bridge management, and monitoring.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Sections](#sections)
  - [Network Management](#network-management)
  - [Firewall Management (nftables)](#firewall-management-nftables)
  - [Open vSwitch (OVS) Bridge Management](#open-vswitch-ovs-bridge-management)
  - [Monitoring](#monitoring)


## Features

- User-friendly TUI interface for easy navigation and configuration
- Network configuration management
- Firewall rule management with nftables (including access rules and NAT)
- Open vSwitch bridge management
- Real-time monitoring of network settings

## Installation

1. Clone the repository:

   ```bash
   git clone https://igit.partdp.ir/j.afkhami/j.afkhami.git
   cd network-configuration-tool
2. Build the project:

	```bash
	make
3. Run the following command

	```bash
	sudo ./main.sh

## Usage

Upon launching the application, you will be presented with the main menu. Navigate through the options using the arrow keys and follow the prompts to configure your network settings, manage the firewall, or monitor your network.

## Sections

### Network Management

In this section, you can view and configure network interfaces, assign IP addresses, and manage routing settings. The intuitive interface allows for easy adjustments and real-time feedback.

### Firewall Management (nftables)

This section provides tools for managing your firewall settings using nftables. You can:

- Write access rules
- Configure Network Address Translation (NAT)
- List existing rules and modify them as needed

### Open vSwitch (OVS) Bridge Management

Manage your OVS bridges with options to create, delete, and configure bridge settings. This section allows you to manage virtual network infrastructure efficiently.

### Monitoring

Monitor real-time network performance and status. This section provides insights into network activity, interface statistics, and alerts for any configuration issues.

