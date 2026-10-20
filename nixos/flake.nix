{
  description = "xboxzzaw13's NixOS config";

  inputs.nixpkgs.url = "https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable/nixexprs.tar.xz";
  
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations."Ac0-Nomad" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
} 
