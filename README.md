# Bash Pass

<img src="./.assets/icon-full.png" width="75"/>

Tunnel your terminal session into any other system session, allowing "session parasitizing".

<img src="./.assets/hero.png" width="350"/>

*This repo is a part of the Cawnsole collection; Improving the HTPC experience.*

[![Patreon](https://img.shields.io/badge/Patreon-%23F96854.svg?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ProCrow) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-%23F16061.svg?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/gwencrow)

<hr>

## What Bash Pass Does

Bash Pass allows a shell within the system to access other sessions and parasitize them; allowing the shell to behave as it if was originally sourced from the target session.

The app itself It detects active sessions with `loginctl` and then grafts the selected session's environment into a fresh interactive shell running as the target user.

When the target session ends, or the app is closed, all non-detached processes will also be ended.

***Bash Pass is basically a back door to your system, use Bash Pass with care, don't be a dunce.***

### Session Parasitizing

**The moniker I made for what Bash Pass does is "session parasitizing".** Like a parasite, the app latches onto a host session and uses the host session's own credentials to burrow in and start asserting its will *(maybe a bit too personified of a description, but I think it gets the point across in a fun visual way)*.


## Installation

### Requirements

| Required | |
| --- | --- |
| Linux host with systemd | |
| Root access | |

| Semi-Required | Notes |
| --- | --- |
| `util-linux` (`script`) | required for `-audit` & `-wanted` arguments |
| `dialog-utility` | required for '-assist' argument |

### Install & Run Bash Pass

## Installing Bash Pass

1. Clone the repo, or download from releases
2. Run the `install-bash-pass.sh` install script

## Running Bash Pass

**There are two ways you can run Bash Pass assuming you installed it.**

**First**: Run Bash Pass with the command `bashpass` (requires that you installed Bash Pass)

**Second**: Run Bash Pass `pass` file as a regular bash script in a shell

*Bash Pass always requires root access to run.*

## Using Bash Pass

Bash Pass is stylized as a friendly "pass" creation app, which then uses the created "pass" to access sessions (parasitize onto selected sessions). *This styling of the app extends to its argument names, terminology, and defaults.* 

1. Run Bash Pass **with sudo privilege** from any shell interface (including SSH)
2. Select the desired session to parasitize
3. Use the shell as if it was running them locally in that session
4. Type `exit` to detach from the session

### Advanced Usage

Bash Pass offers a wide variety of use cases by supporting a large number of arguments; which for the most part can be used with one another to create powerful functionality. The arguments also allows Bash Pass to be embedded within larger workflows.

| Option | Description |
| --- | --- |
| `-silent` | Suppress all visual feedback and menus. |
| `-list [SORT]` | Display the detected environments without entering one. If `SORT` is provided, filter the list. |
| `-pass [DEST]` | Auto-select the first environment matching `DEST` (matched against user, uid, tty, or type), or the special values `oldest` / `latest`. |
| `-location [PATH]` | Drop into `PATH` upon connection. Fails if the path is missing. |
| `--location [PATH]` | Drop into `PATH` upon connection. Falls back to the default directory if missing. |
| `-audit [PATH]` | Save clean terminal output (ANSI colours stripped) to `PATH` or the default location. |
| `--audit [PATH]` | Save raw terminal output to `PATH` or the default location. |
| `-wanted [STR] [CMD]` | Monitor the session stream for `STR`. Exits when it appears, or executes `CMD` if provided. |
| `-only [CMD]` | Execute `CMD` upon connection, then immediately terminate the session. |
| `-first [CMD]` | Execute `CMD` automatically upon connection, before handing over control. |
| `-last [CMD]` | Execute `CMD` automatically when the session terminates. |
| `-timer [TIME]` | Set an automatic disconnect timeout (e.g. `3.5d`, `5D2H`, `30m`, `10s`). |
| `-help` | Display the full option reference and exit. |

*For a more detailed breakdown of how to use each argument (with examples) check the wiki markdown.*

### Notes

- Audit files default to `/tmp/bash-pass/audits/`.
- `-only` cannot be combined with `-first` or `-last`.
- `-wanted` without `CMD` ends the session the moment `STR` appears.
- `-pass` / `-list` matching is a substring match against any column. Graphical sessions are labelled `wayland display` / `x11 display`, so `-pass display` targets the first graphical session.
- `-silent` is handy for automation: no menus, no banners, no flavour text.
