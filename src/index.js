#!/usr/bin/env node

const { program } = require('commander');
const fs = require('fs');
const path = require('path');
const packageJson = require('../package.json');

let airdropNative;
try {
  airdropNative = require('../build/Release/airdrop_native');
} catch (err) {
  console.error('❌ Error: Native module not built. Try running "npm rebuild airdrop-cli".');
  process.exit(1);
}

class AirDropCLI {
  constructor() {
    this.setupCommander();
  }

  setupCommander() {
    program
      .name('airdrop')
      .description('AirDrop CLI for file sharing on macOS')
      .version(packageJson.version)
      .argument('<file>', 'File or URL to share via AirDrop')
      .option('-h, --help', 'Show help information')
      .action(async (file, options) => {
        if (options.help || !file) {
          this.printUsage();
          return;
        }

        await this.shareFile(file);
      });

    program.parse();
  }

  printUsage() {
    console.log('Usage: airdrop <file>');
    console.log('');
    console.log('Arguments:');
    console.log('  file    URL or path to file to share via AirDrop');
    console.log('');
    console.log('Options:');
    console.log('  -h, --help  Show help information');
    console.log('');
    console.log('Examples:');
    console.log('  airdrop /path/to/file.txt');
    console.log('  airdrop https://apple.com/');
  }

  async shareFile(file) {
    console.log('\n🚀 Preparing to share:');

    let validFile;

    if (this.isURL(file)) {
      console.log(`   🌐 ${file}`);
      validFile = file;
    } else {
      const absolutePath = path.resolve(file);
      if (fs.existsSync(absolutePath)) {
        const fileName = path.basename(absolutePath);
        console.log(`   📄 ${fileName}`);
        validFile = absolutePath;
      } else {
        console.error(`❌ File not found: ${file}`);
        process.exit(1);
      }
    }

    console.log('\n📡 Opening AirDrop...');

    try {
      const result = airdropNative.shareFile(validFile);
      if (result) {
        console.log('✅ Successfully shared via AirDrop!\n');
      }
    } catch (error) {
      console.error(`❌ Failed: ${error.message}\n`);
      throw error;
    }
  }

  isURL(string) {
    try {
      const url = new URL(string);
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch {
      return false;
    }
  }
}

if (process.platform !== 'darwin') {
  console.error('❌ Error: This tool only works on macOS');
  process.exit(1);
}

new AirDropCLI();
