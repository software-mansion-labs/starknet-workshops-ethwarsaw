# StarkNet Workshops @ EthWarsaw

## General information
You will learn what StarkNet is, how it works and why it’s so good. We’ll introduce you to the Cairo language, StarkNet ecosystem and tools. Then, in the practical part, you’ll build and deploy your own smart contract. No prior blockchain experience required, although we assume you have some general programming knowledge.

### 📆 September 2nd, 4 PM CEST
### 📍 Warsaw University of Technology - [map](https://goo.gl/maps/diZ5qW1p2Buafmtv9)
### 🌎 Conference website - [go](https://www.ethwarsaw.dev)

### 🖥 [Presentation slides](https://docs.google.com/presentation/d/1EtMje9-22sNJA0woz0vqceHYwU8BuoxxuEVcXZpiuCE/edit?usp=sharing)

## Downloading the repository
Please run:
```shell
git clone --recurse-submodules https://github.com/software-mansion-labs/starknet-workshops-ethwarsaw.git
```

## Setting up the environment

To follow the workshops along, you'll need some tools. Please follow these instructions, to install them.

### Protostar
It's a toolchain for developing and testing Cairo smart contracts (think Hardhat for StarkNet).

To install it, run:

```shell
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```

### Python

Make sure you have python set up. Any version between 3.7 and 3.10 will work, so If you have it already installed just skip this step, if not, just copy into your terminal:

```shell
brew install python@3.7
```
if you're working on Mac, or
```shell
sudo apt install python3.7
```
otherwise.

## Visual Studio Code setup

If you use VSCode, use these two plugins to significantly improve Cairo writing experience.
### Cairo language support for StarkNet
Find it directly in vscode plugins page, or download from:
https://marketplace.visualstudio.com/items?itemName=ericglau.cairo-ls

![Zrzut ekranu 2022-08-30 o 16 23 18](https://user-images.githubusercontent.com/16562410/187462579-27e8d7a5-5df4-4e25-9f29-7208f11ba91d.png)

### Cairo syntax highlighting
Download the Cairo Visual Studio Code extension (`cairo-0.9.1.vsix`) from https://github.com/starkware-libs/cairo-lang/releases/tag/v0.9.1, and install it using:

```shell
code --install-extension cairo-0.9.1.vsix
```
Configure Visual Studio Code settings:
```json
"editor.formatOnSave": true,
"editor.formatOnSaveTimeout": 1500
```

**Note**: You should start Visual Studio Code from the terminal *running the virtual environment*, by typing code. For instructions for macOS, see [here](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line).

## Other IDEs

If you don't use VSCode, follow instructions provided here https://github.com/ericglau/cairo-l

## Setting up Argent X wallet (optional)
You'll need a wallet, that's compatibile with starknet.
Go [here](https://www.argent.xyz/argent-x/) to download Argent X extention for your browser, install it and create your wallet by following displayed instructions.

## Cairo Cheat Sheet

# Link to telegram group

If you have further questions for this workshop, feel free to ask them here:

https://t.me/+lg3D231WTb04YzU8
