# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  # Hardware scan results like disk UUISd and kernel modules etc.
  imports = [ ./hardware-configuration.nix ];

  # Allow NixOS to use non-FOSS like Vivaldi browser
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "HOSTNAME";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Window manager
  programs.hyprland.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Terminal
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
    earlySetup = true;
  };

  # Printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    # nssdmns4 = true;
    openFirewall = true;
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Support removable drives
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.USERNAME = {
    isNormalUser = true;
    description = "Primary User";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ]; # Enable 'sudo' for the user.
    packages = with pkgs; [
      tree
    ];
  };

  # programs.firefox.enable = true;

  # Steam requires special configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget

    kitty
    wofi

    waybar
    swaynotificationcenter
    libnotify

    hyprpaper
    hyprlock
    wlr-randr

    git
    vivaldi
    wl-clipboard

    udiskie
    xfce.thunar
    xfce.thunar-volman

    htop
    neofetch

    neovim

    vscode
    vscodium
    claude-code

    networkmanagerapplet

    # Productivity & Notes
    obsidian
    zotero
    libreoffice

    # Browsers
    chromium

    # Media
    vlc
    gimp
    mpv
    obs-studio
    spotify
    yt-dlp
    ani-cli
    ffmpeg

    # Communication
    thunderbird
    discord
    wasistlos
    telegram-desktop
    signal-desktop

    # System & Terminal
    btop
    wlsunset
    jq
    cmatrix
    yazi
    fzf

    # VPN
    protonvpn-gui

    # AI Tools
    gemini-cli

    # Graphics
    inkscape

    # Image creation for wallpapers etc
    imagemagick

    # Cursor theme
    adwaita-icon-theme
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.symbols-only
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
