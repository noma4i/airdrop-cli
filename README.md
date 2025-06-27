# AirDrop CLI

AirDrop CLI for file sharing on macOS.


### Prerequisites

- macOS 10.12 or later
- Xcode Command Line Tools: `xcode-select --install`

### Installation

```bash
npm install -g airdrop-cli
```

## Usage

```bash
# Share a file
airdrop /path/to/file.txt

# Share a URL
airdrop https://apple.com
```

## Features

Can send files from the terminal

`airdrop https://apple.com`

<img src="media/screenshot.png" alt="AirDrop CLI Demo" width="600">


## Options

```
Usage: airdrop <file>

Arguments:
  file    URL or path to file to share via AirDrop

Options:
  -h, --help     Show help information
  -V, --version  Show version number
```

## Inspiration

This project was inspired by [vldmrkl/airdrop-cli](https://github.com/vldmrkl/airdrop-cli).

## License

MIT
