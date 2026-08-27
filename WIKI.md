# Bash Pass

## What is Bash Pass?
Bash Pass is a system tool for parasitizing active system sessions; it latches onto a host session and uses the host session's own credentials to "burrow in", letting your shell behave as if it was originally sourced from that session. 

*I originally designed this for managing an HTPC over SSH, but it works from any shell interface, and its arguments make it embeddable in much larger workflows.*

## How Does Bash Pass Work?

Bash Pass detects active system sessions with `loginctl`, then grafts the selected session's environment (`user`, `uid`, `tty`, and session type) into a fresh interactive shell running as the target user. The shell behaves as if it was originally sourced[ from the target](url) session.

When the target session ends, or Bash Pass itself is closed, all non-detached processes started through it are ended as well.

### Security
Bash Pass is basically a backdoor to your system sessions. The only real security measure Bash Pass has is the requirement of root access to run, *but that is more of a necessity for functionality than a security measure*. The program is insecure by design. That means YOU are the security measure. Do not let strangers use this app on your system. Don't be a dunce in general. 

## Requirements

| Required | Notes |
| --- | --- |
| Linux host with systemd | session detection relies on `loginctl` |
| Root access | Bash Pass will not run without it |

| Semi-Required | Notes |
| --- | --- |
| `util-linux` (`script`) | required for `-audit` & `-wanted` |
| `dialog-utility` | required for `-assist` |

## Installation

1. Clone the repo, or download from releases
2. Run the `install-bash-pass.sh` install script or install manually

**The install script copies `pass` into `/usr/local/bin` as the `bashpass` command**, alongside the `bash-pass-help` file it needs for `-help` (the app resolves its help text relative to its own location, so the two must stay side by side). To install somewhere else, pass the directory as an argument (it must be on `PATH`):

`sudo ./install-bash-pass.sh /custom/path`

**To remove the installed files: `sudo ./install-bash-pass.sh -uninstall`**

## Using Bash Pass

Bash Pass can be used in a variety of ways due to its simple and flexible architecture. Simply running Bash Pass plainly is enough for most use cases, but that is the tip of the iceberg. Embedding Bash Pass into larger scripts, making full use of the available arguments, is where the real possibilities are. 

**Once installed, run Bash Pass with the `bashpass` command**. *Alternatively, run the `pass` file directly as a regular bash script in a shell (e.g. `sudo bash pass`)*. Both require root access.

### Arguments

Bash Pass offers a lot of arguments to unlock advanced functionality.

For the argument examples below, [Bash Pass RUN] represents Bash Pass being run. The order of arguments is not important.

| Argument | Description | Example |
| --- | --- | --- |
| **`-assist`** | **Renders the session list with the `dialog` utility**, allowing you to click on the screen to make the selection. *The normal text-based session list requires the user to input a number and then press enter, which can be a problem for setups where accessing those keys is difficult*. | `[Bash Pass RUN] -assist` |
| **`-silent`** | **Suppresses all feedback other than input querying.** To suppress input querying as well, use this argument with other arguments that will handle the session selection, avoiding input querying & suppressing all feedback as a result.<br>*This argument helps with embedding Bash Pass into larger workflows where the feedback may cause problems*. | `[Bash Pass RUN] -silent`<br>`[Bash Pass RUN] -silent -pass`<br>`[Bash Pass RUN] -pass latest -silent`<br>`[Bash Pass RUN] --pass guest -only logout -silent` |
| **`-pass`** *`[DESTINATION]`* | **Skips showing the session selection list and auto-selects the first indexed session.** The optional variable `[DESTINATION]` is a string that is matched against the session list, causing the argument to select the first match for `[DESTINATION]` rather than the first session indexed.<br>**There are two special variables for `[DESTINATION]`**; "**`oldest`**" (*selects the oldest session*) & "**`latest`**" (*selects the newest session*). | `[Bash Pass RUN] -pass`<br>`[Bash Pass RUN] -pass wayland`<br>`[Bash Pass RUN] -pass oldest`<br>`[Bash Pass RUN] -first "echo 'here'" -pass latest -audit` |
| **`--pass`** **`[DESTINATION]`** | **Identical to `-pass`, except `[DESTINATION]` is required**; on failure there is an error and Bash Pass does not run. | `[Bash Pass RUN] --pass x11 -only "notify-send 'Use wayland' && sleep 5 && logout" -silent` |
| **`-location`** *`[PATH]`* | **Changes the default location from the target session owner's home directory to `[PATH]`.** If Bash Pass fails to find the defined `[PATH]`, the location will revert to the default location. *By default Bash Pass will parasitize onto a session at `/home/[user]/` where [user] is the corresponding session's owner*.<br>The `[PATH]` variable supports `~/` as shorthand for `/home/[user]/`. | `[Bash Pass RUN] -location /tmp`<br>`[Bash Pass RUN] -location ~/Desktop` |
| **`--location`** **`[PATH]`** | **Identical to `-location`, except `[PATH]` is required**; on failure there is an error and Bash Pass does not run, rather than using the default location. | `[Bash Pass RUN] --location /tmp`<br>`[Bash Pass RUN] --location ~/Desktop` |
| **`-first`** **`[CMD]`** | **Upon connection to a session, executes `[CMD]` as detached.** The variable `[CMD]` can be any string of text. Use quotes to wrap `[CMD]` if it has spaces or may interfere with other arguments. *If `[CMD]` is missing, this argument will do nothing*. | `[Bash Pass RUN] -first steam`<br>`[Bash Pass RUN] -first "notify-send 'Get the popcorn' && netflix"` |
| **`-last`** **`[CMD]`** | **Upon disconnection from a session, executes `[CMD]` as detached.** The variable `[CMD]` can be any string of text. Use quotes to wrap `[CMD]` if it has spaces or may interfere with other arguments. *If `[CMD]` is missing, this argument will do nothing*. | `[Bash Pass RUN] -last "echo 'See you later!'"` |
| **`-only`** **`[CMD]`** | **Upon connection to a session, executes `[CMD]` as detached, and then immediately disconnects from the session.** The variable `[CMD]` can be any string of text. Use quotes to wrap `[CMD]` if it has spaces or may interfere with other arguments. *If `[CMD]` is missing, this argument will execute nothing, but will still immediately disconnect from the session upon making a connection*.<br>**The argument `-only` cannot be used with the arguments `-first` & `-last`.** | `[Bash Pass RUN] -only "shutdown -r now"` |
| **`-audit`** *`[PATH]`* | **Saves a clean output of the entire terminal session interaction at /tmp/bash-pass/audits/.** *The output is saved as a plain text receipt file named after the sudo user (`[user]`) and the type of session parasitized (`[environment]`): `[user]-[environment]_SSMMHH—DD-MM-YYYY.txt`, e.g. `crow-wayland_45S27M14H—26-08-2025.txt`.*<br>**If the desired file already exists, the receipt is saved under the default filename in the same directory.** **Defining `[PATH]` changes where the receipt file is saved.** *Any failure to save at the desired location will cause the receipt file to be written to the default location.* | `[Bash Pass RUN] -audit`<br>`[Bash Pass RUN] -audit /etc/audits`<br>`[Bash Pass RUN] -audit "~/Desktop/Audit Files"` |
| **`--audit`** *`[PATH]`* | **Identical to `-audit`, except all raw terminal output for the session interaction is saved.** | `[Bash Pass RUN] --audit`<br>`[Bash Pass RUN] --audit /etc/audits` |
| **`-wanted`** **`[STR]`** *`[CMD]`* | **Monitors all terminal text during session interaction for an exact match for `[STR]`.** By default, if `[STR]` is matched, Bash Pass will automatically disconnect from the session. If `[CMD]` is defined, `[CMD]` is executed upon `[STR]` match instead of disconnecting from the session.<br>The `[STR]` variable can handle multiple strings in the format `"string one","string two","string three"`, allowing a single `-wanted` argument to look for multiple values. `-wanted` may also be used multiple times in a single Bash Pass command; every watch string stays active, and a `[CMD]` executes when any string of its own `-wanted` use is matched. Monitoring ends on the first match. | `[Bash Pass RUN] -wanted error`<br>`[Bash Pass RUN] -wanted "All Clear","All Green"`<br>`[Bash Pass RUN] -wanted ready "go build"`<br>`[Bash Pass RUN] -wanted "not found" "echo 'HERE'"`<br>`[Bash Pass RUN] -wanted ready "go build" -wanted "Build failed" "echo 'FAILED'"` |
| **`-timer`** **`[TIME]`** *`[WARNTIME]`* *`[WARNEXEC]`* | **Triggers disconnection of the session interaction once [TIME] is reached.** The optional `[WARNTIME]` variable triggers a single warning once it has elapsed; if missing, no warning is given. The optional `[WARNEXEC]` variable is a string that, if defined, is executed when the warning fires, including when running with `-silent`.<br>*The [TIME] format can be varied (e.g. 5s, 10m, 1h, 1.5d, 2D3H).* | `[Bash Pass RUN] -timer 10m`<br>`[Bash Pass RUN] -timer 1h 10m "echo 'running out'"` |
| **`--timer`** **`[TIME]`** **`[TIMEXEC]`** | **Identical to `-timer`, except instead of disconnecting from the session on expiry, the `[TIMEXEC]` string is executed.** May be repeated to set multiple timers; each timer still triggers the standard warning (suppressed with `-silent`, though the command still runs). | `[Bash Pass RUN] --timer 10s "echo 'get started'"`<br>`[Bash Pass RUN] --timer 20s "echo 'wind down'"` |
| **`-list`** *`[SORT]`* | **Displays an index of available sessions.** If the optional variable `[SORT]` is defined, the sessions will be filtered by the `[SORT]` string. | `[Bash Pass RUN] -list`<br>`[Bash Pass RUN] -list wayland`<br>`[Bash Pass RUN] -list x` |
| `-help` / `--help` / `-h` | **Displays the default help text.** The help text is within the `bash-pass-help` file, and this argument requires the file to work. | `[Bash Pass RUN] -help`<br>`[Bash Pass RUN] --help`<br>`[Bash Pass RUN] -h` |
| **`-version`** | **Displays the current version number.** | `[Bash Pass RUN] -version` |

### Use Case Examples

The examples below are grouped by intent. Arguments are order-independent, so any combination shown can be rearranged; the Arguments table above is the full reference.

#### Remote Control & Administration

| Purpose | Command |
| --- | --- |
| **One-shot remote command**: run a command inside a session and disconnect immediately | `[Bash Pass RUN] -only "notify-send 'Backup finished'"` |
| **Remote reboot**: power-cycle the machine from a session | `[Bash Pass RUN] -only "shutdown -r now"` |
| **Launching a graphical app**: start an app in the target session, then hand over control | `[Bash Pass RUN] -first "notify-send 'Get the popcorn' && netflix"` |
| **Start work in a specific directory**: drop into a chosen folder and run something there (`-location` falls back to the default directory if the path is missing) | `[Bash Pass RUN] -pass x11 -location ~/Videos -first "vlc movie.mp4"` |
| **Touchscreen / remote selection**: render the session list as a clickable dialog instead of typed numbers (requires `dialog-utility`) | `[Bash Pass RUN] -assist` |

#### Automation & Scripting

| Purpose | Command |
| --- | --- |
| **Fully silent, scripted run**: no menus or prompts; the argument combination does all the selecting | `[Bash Pass RUN] -silent -pass guest -only logout` |
| **Scheduled maintenance**: take over the newest session silently, run a task, announce when it is done, and leave a receipt | `[Bash Pass RUN] -silent -pass latest -location /tmp -first "backup.sh" -last "notify-send 'Backup complete'" -audit -timer 90m` |
| **Session inventory in scripts**: check which sessions exist without entering one | `[Bash Pass RUN] -list wayland` |

#### Monitoring & Waiting

| Purpose | Command |
| --- | --- |
| **Watch a build**: monitor the session stream and disconnect the moment a marker appears | `[Bash Pass RUN] -wanted "All Clear"` |
| **Fail fast with a notification**: instead of disconnecting, run a command when the marker shows | `[Bash Pass RUN] -wanted "Build failed" "echo 'Build failed' \| wall"` |
| **Wait for a service**: hold the session until a server announces it is listening | `[Bash Pass RUN] -wanted "Listening on port 8080"` |

#### Time Limits

| Purpose | Command |
| --- | --- |
| **Hard cutoff with warning**: disconnect after 30 minutes, with a warning at 25 | `[Bash Pass RUN] -timer 30m 25m "echo '5 minutes left'"` |
| **Gentle reminders**: never disconnect; run a command at set times instead (`--timer` can be repeated) | `[Bash Pass RUN] --timer 20m "notify-send 'Time check'" --timer 40m "notify-send 'Almost done'"` |
| **Fixed-window session**: a session interaction that ends itself after an hour, with a warning at 10 minutes | `[Bash Pass RUN] -timer 1h 10m "echo '10 minutes left'"` |

#### Auditing & Records

| Purpose | Command |
| --- | --- |
| **Clean session receipt**: save a sanitized (ANSI-stripped) copy of the interaction | `[Bash Pass RUN] -audit` |
| **Receipt to a custom location** | `[Bash Pass RUN] -audit "~/Desktop/Audit Files"` |
| **Raw capture**: byte-for-byte terminal output | `[Bash Pass RUN] --audit /var/log/bash-pass` |
| **Audit + monitoring combined**: record the session and auto-disconnect on a marker | `[Bash Pass RUN] -audit -wanted error` |

## Notices

### License

Bash Pass is free software, licensed under the **GNU General Public License, version 3 (GPL-3.0)**; the full license text is in the `LICENSE` file of this repository.

The GPL-3.0 grants you the freedom to use, study, share, and modify Bash Pass, provided any copies or derivatives you distribute remain under the GPL-3.0.

**No warranty.** Bash Pass is distributed in the hope that it will be useful, but **without any warranty**: not even the implied warranties of merchantability or fitness for a particular purpose (GPL-3.0, section 15). Given what this program does (see *Security* above), you use it entirely at your own risk.

### Disclaimer

I originally made this as a small-scale program for myself to help me interact with my HTPC. After using it for a while, I realized how useful Bash Pass could be with some effort. I have no clue what the maximum scope of functionality might be, but I made sure the features I added could work together and cover every edge case I could imagine.  

I used AI to help write code comments, some of the logic-based functionality of this program, and some editing/ auditing (such as grammar help & license), all under my scrutiny. Otherwise, everything about this program, from how it interacts with the user to every letter in the help feedback, was created by me directly. Every development decision was mine, and every idea was one I came up with myself. There was never a point where I allowed an AI to steer the course of development.