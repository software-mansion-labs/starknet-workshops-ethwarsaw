# starknet-workshops-ethwarsaw

## Setting up Argent X wallet
Go [here](https://www.argent.xyz/argent-x/) to download Argent X extention for your browser, install it and create your wallet by following displayed instructions.

## Setting up the environment

### Protostar

To install protostar, run:

```shell
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```

### Python

Any version between 3.7 and 3.10 will work, so If you have it already installed just skip this step, if not, just copy into your terminal:

```shell
brew install python@3.7
```
if you're working on Mac, or
```shell
sudo apt install python3.7
```
otherwise.

## Visual Studio Code setup
Download the Cairo Visual Studio Code extension (`cairo-0.9.1.vsix`) from https://github.com/starkware-libs/cairo-lang/releases/tag/v0.9.1, and install it using:

```shell
code --install-extension cairo-0.9.1.vsix
```
Configure Visual Studio Code settings:
```json
"editor.formatOnSave": true,
"editor.formatOnSaveTimeout": 1500
```
**Note**: You should start Visual Studio Code from the terminal *running the virtual environment*, by typing `code`. For instructions for macOS, see [here](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line).

## Cairo Cheat Sheet
