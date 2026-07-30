#!/bin/bash

# Startup script for Google Cloud VM instances
# Supports: --install-docker, --mount-external-disk flags

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/startup-script.log"

# Default flag values
INSTALL_DOCKER=false
MOUNT_EXTERNAL_DISK=false

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_warning() {
    log "WARNING" "$@"
}

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-docker)
                INSTALL_DOCKER=true
                log_info "Docker installation requested"
                shift
                ;;
            --mount-external-disk)
                MOUNT_EXTERNAL_DISK=true
                log_info "External disk mounting requested"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Help function
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

OPTIONS:
    --install-docker        Install Docker CE
    --mount-external-disk   Mount external disk at /mnt
    -h, --help             Show this help message

Examples:
    $SCRIPT_NAME --install-docker
    $SCRIPT_NAME --mount-external-disk
    $SCRIPT_NAME --install-docker --mount-external-disk

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# System readiness check
check_system_ready() {
    log_info "Checking system readiness..."
    
    # Wait for package manager to be available
    local retries=30
    while ! apt-get update &>/dev/null && [[ $retries -gt 0 ]]; do
        log_info "Waiting for package manager to be ready... ($retries retries left)"
        sleep 10
        ((retries--))
    done
    
    if [[ $retries -eq 0 ]]; then
        error_exit "Package manager failed to become ready"
    fi
    
    log_info "System is ready"
}

# Docker installation function
install_docker() {
    if [[ "$INSTALL_DOCKER" == true ]]; then
        log_info "=== Starting Docker installation ==="
        
        # Check if Docker is already installed
        if command -v docker &> /dev/null; then
            local docker_version=$(docker --version 2>/dev/null || echo "unknown")
            log_info "Docker is already installed. Version: $docker_version"
            
            # Still check if Docker daemon is running
            if systemctl is-active --quiet docker; then
                log_info "Docker service is running"
            else
                log_info "Docker service is not running, starting it..."
                systemctl start docker
                systemctl enable docker
            fi
            return 0
        fi
        
        log_info "Installing Docker CE for Ubuntu..."
        
        # Remove any old Docker packages
        log_info "Removing any conflicting Docker packages..."
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Update package index
        log_info "Updating package index..."
        if ! apt-get update; then
            error_exit "Failed to update package index"
        fi
        
        # Install required packages for Docker repository
        log_info "Installing prerequisites..."
        if ! apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release; then
            error_exit "Failed to install prerequisite packages"
        fi
        
        # Add Docker's official GPG key
        log_info "Adding Docker GPG key..."
        mkdir -p /etc/apt/keyrings
        
        # Remove existing key if present
        rm -f /etc/apt/keyrings/docker.gpg
        
        if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
            error_exit "Failed to add Docker GPG key"
        fi
        
        # Set proper permissions on the key
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Add Docker repository
        log_info "Adding Docker repository..."
        local ubuntu_codename=$(lsb_release -cs)
        local docker_repo="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $ubuntu_codename stable"
        
        echo "$docker_repo" > /etc/apt/sources.list.d/docker.list
        
        # Update package index with Docker repository
        log_info "Updating package index with Docker repository..."
        if ! apt-get update; then
            error_exit "Failed to update package index after adding Docker repository"
        fi
        
        # Install Docker Engine
        log_info "Installing Docker Engine, CLI, and containerd..."
        if ! apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
            error_exit "Failed to install Docker packages"
        fi
        
        # Start and enable Docker service
        log_info "Starting and enabling Docker service..."
        if ! systemctl start docker; then
            error_exit "Failed to start Docker service"
        fi
        
        if ! systemctl enable docker; then
            error_exit "Failed to enable Docker service"
        fi
        
        # Wait a moment for Docker to fully start
        sleep 3
        
        # Verify Docker installation
        log_info "Verifying Docker installation..."
        if ! docker --version; then
            error_exit "Docker installation verification failed - docker command not working"
        fi
        
        # Test Docker daemon
        if ! docker info &>/dev/null; then
            error_exit "Docker installation verification failed - Docker daemon not responding"
        fi
        
        # Run hello-world container as final test
        log_info "Running Docker hello-world test..."
        if ! docker run --rm hello-world &>/dev/null; then
            log_warning "Docker hello-world test failed, but Docker appears to be installed correctly"
        else
            log_info "Docker hello-world test passed"
        fi
        
        # Add ubuntu user to docker group (if ubuntu user exists)
        if id "ubuntu" &>/dev/null; then
            log_info "Adding ubuntu user to docker group..."
            usermod -aG docker ubuntu
            log_info "Ubuntu user added to docker group. User will need to log out and back in for group changes to take effect."
        fi
        
        # Add any other common users to docker group
        for user in admin; do
            if id "$user" &>/dev/null; then
                log_info "Adding $user user to docker group..."
                usermod -aG docker "$user"
            fi
        done
        
        # Log Docker version and status
        local docker_version=$(docker --version)
        local docker_compose_version=$(docker compose version 2>/dev/null || echo "Docker Compose: not available")
        
        log_info "Docker installation successful!"
        log_info "  - $docker_version"
        log_info "  - $docker_compose_version"
        log_info "  - Docker daemon status: $(systemctl is-active docker)"
        log_info "  - Docker daemon enabled: $(systemctl is-enabled docker)"
        
        # Clean up
        log_info "Cleaning up installation artifacts..."
        apt-get autoremove -y &>/dev/null || true
        apt-get autoclean &>/dev/null || true
        
        log_info "=== Docker installation completed ==="
    fi
}

# External disk mounting function
mount_external_disk() {
    if [[ "$MOUNT_EXTERNAL_DISK" == true ]]; then
        log_info "=== Starting external disk mounting ==="
        
        # Check if disk is already mounted at /mnt
        if mountpoint -q /mnt 2>/dev/null; then
            log_info "External disk is already mounted at /mnt"
            return 0
        fi
        
        # Detect external disk (usually /dev/sdb for the first external disk)
        local external_disk=""
        for disk in /dev/sd{b..z} /dev/nvme{1..9}n1; do
            if [[ -b "$disk" ]]; then
                external_disk="$disk"
                log_info "Found external disk: $external_disk"
                break
            fi
        done
        
        if [[ -z "$external_disk" ]]; then
            error_exit "No external disk found. Expected disk at /dev/sdb or similar."
        fi
        
        # Safety check: Ensure disk doesn't have an existing filesystem
        log_info "Checking if disk $external_disk has existing filesystem..."
        
        # Check for existing filesystem using multiple methods
        local has_filesystem=false
        
        # Method 1: Check with blkid
        if blkid "$external_disk" &>/dev/null; then
            local existing_fs=$(blkid -o value -s TYPE "$external_disk" 2>/dev/null || echo "")
            if [[ -n "$existing_fs" ]]; then
                log_info "Found existing filesystem: $existing_fs"
                has_filesystem=true
            fi
        fi
        
        # Method 2: Check with file command for more thorough detection
        if ! $has_filesystem; then
            local file_output=$(file -s "$external_disk" 2>/dev/null || echo "")
            if [[ "$file_output" != *"data"* ]] && [[ "$file_output" != *"/dev/"*": data" ]]; then
                log_info "File command detected potential filesystem: $file_output"
                has_filesystem=true
            fi
        fi
        
        # Method 3: Check first few sectors for any data patterns
        if ! $has_filesystem; then
            local first_sectors=$(dd if="$external_disk" bs=1024 count=1 2>/dev/null | hexdump -C | head -10)
            if [[ -n "$first_sectors" ]] && [[ "$first_sectors" != *"00000000"* ]]; then
                # Check if it's all zeros (truly empty disk)
                local zero_check=$(dd if="$external_disk" bs=1024 count=1 2>/dev/null | od -t x1 | grep -v "000000")
                if [[ -n "$zero_check" ]]; then
                    log_warning "Disk appears to have data in first sectors"
                    has_filesystem=true
                fi
            fi
        fi
        
        if $has_filesystem; then
            log_info "Disk has existing filesystem. Attempting to mount without formatting..."
            
            # Try to mount existing filesystem
            mkdir -p /mnt
            if mount "$external_disk" /mnt; then
                log_info "Successfully mounted existing filesystem at /mnt"
            else
                error_exit "Failed to mount existing filesystem on $external_disk"
            fi
        else
            log_info "Disk appears to be empty. Proceeding with formatting..."
            
            # Format the disk with ext4
            log_info "Formatting $external_disk with ext4 filesystem..."
            if ! mkfs.ext4 -F "$external_disk"; then
                error_exit "Failed to format disk $external_disk"
            fi
            
            log_info "Formatting completed successfully"
            
            # Create mount point and mount
            mkdir -p /mnt
            if ! mount "$external_disk" /mnt; then
                error_exit "Failed to mount formatted disk $external_disk at /mnt"
            fi
            
            log_info "Successfully mounted formatted disk at /mnt"
        fi
        
        # Add to /etc/fstab for persistent mounting
        local disk_uuid=$(blkid -o value -s UUID "$external_disk")
        if [[ -n "$disk_uuid" ]]; then
            local fstab_entry="UUID=$disk_uuid /mnt ext4 defaults,nofail 0 2"
            
            # Check if entry already exists
            if ! grep -q "$disk_uuid" /etc/fstab; then
                echo "$fstab_entry" >> /etc/fstab
                log_info "Added disk to /etc/fstab for persistent mounting: $fstab_entry"
            else
                log_info "Disk already present in /etc/fstab"
            fi
        else
            log_warning "Could not get UUID for $external_disk, skipping /etc/fstab entry"
        fi
        
        # Set proper permissions
        chown root:root /mnt
        chmod 755 /mnt
        
        # Verify mount
        if mountpoint -q /mnt; then
            local disk_info=$(df -h /mnt | tail -1)
            log_info "External disk successfully mounted: $disk_info"
        else
            error_exit "Mount verification failed"
        fi
        
        log_info "=== External disk mounting completed ==="
    fi
}

# Main execution function
main() {
    log_info "=== Startup script execution started ==="
    log_info "Script: $SCRIPT_NAME"
    log_info "Arguments: $*"
    
    check_root
    parse_arguments "$@"
    check_system_ready
    
    # Execute requested operations
    install_docker
    mount_external_disk
    
    log_info "=== Startup script execution completed successfully ==="
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Run main function with all arguments
    main "$@"
fi
