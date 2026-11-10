{ ... }:
{
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.upower.enable = true;
  services.fwupd.enable = true;
  # One owner of AC/battery policy, responding to power-source events.
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      # Preserve drivers' runtime PM rules (including NVIDIA RTD3).
      RUNTIME_PM_ON_AC = "";
      RUNTIME_PM_ON_BAT = "";
      USB_AUTOSUSPEND = 0;
    };
  };
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };
}
