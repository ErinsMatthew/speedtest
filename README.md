# speedtest

Run and process Internet speed tests.

## Overview

This script will run and process speed tests using popular services such as
Ookla and Cloudflare.

## Execution

To execute this script, run the following commands once the
dependencies are installed:

```sh
# list possible options and help
$ speedtest.sh -h
$ process-results.sh -h
$ archive-results.sh -h

# run Ookla speed test and output to the current directory
$ speedtest.sh -o -r .

# process speed test results in current directory
$ process-results.sh -r .

# archive results in current directory
$ archive-results.sh -r .
```

## Dependencies

- `cat` - pre-installed with macOS and most Linux distributions
- `cut` - pre-installed with macOS and most Linux distributions
- `gpg` - optional; GNU Privacy Guard; install using [Homebrew](https://formulae.brew.sh/formula/gnupg), another package manager, or [manually](https://gnupg.org/)
- `cfspeedtest` - CloudFlare speed test CLI; install using [Homebrew](https://formulae.brew.sh/formula/openssl@3), another package manager, or [manually](https://www.openssl.org/source/)
- `gdate` - install via coreutils using [Homebrew](https://formulae.brew.sh/formula/coreutils), another package manager, or [manually](https://www.gnu.org/software/coreutils/)
- `gunzip` - install via coreutils using [Homebrew](https://formulae.brew.sh/formula/coreutils), another package manager, or [manually](https://www.gnu.org/software/coreutils/)
- `gzip` - install via coreutils using [Homebrew](https://formulae.brew.sh/formula/coreutils), another package manager, or [manually](https://www.gnu.org/software/coreutils/)
- `mkdir` - pre-installed with macOS and most Linux distributions
- `mv` - pre-installed with macOS and most Linux distributions
- `realpath` - install via coreutils using [Homebrew](https://formulae.brew.sh/formula/coreutils), another package manager, or [manually](https://www.gnu.org/software/coreutils/)
- `rm` - pre-installed with macOS and most Linux distributions
- `speedtest` - Ookla speed test CLI; install using [Homebrew](https://formulae.brew.sh/formula/openssl@3), another package manager, or [manually](https://www.openssl.org/source/)
- `sqlite-utils` - Ookla speed test CLI; install using [Homebrew](https://formulae.brew.sh/formula/sqlite-utils), another package manager, or [manually](https://sqlite-utils.datasette.io/en/stable/installation.html)
- `tar` - pre-installed with macOS and most Linux distributions
- `jq` - pre-installed with macOS and most Linux distributions

## Platform Support

This script was tested on macOS Sequoia (15.3) using GNU Bash 5.2.37(1),
but should work on any GNU/Linux system that supports the dependencies
above.
