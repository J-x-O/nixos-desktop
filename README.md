<h1 align="center">
  <br>
  <img src="https://static.wikia.nocookie.net/silly-cat/images/7/78/Melon_Cat_Species_2.png/revision/latest?cb=20240223181954" alt="MelonCat" width="200"></a>
  <br>
  NixOs Psychose
  <br>
</h1>

<h4 align="center"> Nix Configuration for my two pcs </h4>

<p align="center">

![Version](https://img.shields.io/badge/dynamic/json?label=version&query=$.version&url=https://raw.githubusercontent.com/JoyJab-Games/Project-JoyBoxOS/main/version.json&color=green)

</p>

## Installation

- boot into a [minimal NixOS ISO ](https://nixos.org/download/)
- run the installer script ```bash <(curl -sL https://raw.githubusercontent.com/J-x-O/nixos-desktop/main/bootstrap.sh)```
- profit

## Configuration
If you are setting up an unsupported PC follow these steps:

- Boot the PC from a NixOS ISO.
- Run ```nixos-generate-config --no-filesystems```
- Take the resulting hardware-configuration.nix and create a new hardware config under hosts.