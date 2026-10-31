# Kindle Dash Battery – Low-power Kindle Dashboard with Home Assistant Reporting

Turn an old Kindle into an energy-efficient E-Ink dashboard with optional battery reporting to Home Assistant.

This project is a fork of [pascalw/kindle-dash](https://github.com/pascalw/kindle-dash), originally created by **Pascal Widdershoven**.

It preserves the original low-power dashboard functionality and adds optional Home Assistant integration, including battery reporting via HTTP webhooks.

![Kindle dashboard](./example/photo.jpg)

## What this project does

Kindle Dash Battery runs directly on a jailbroken Kindle device. It periodically downloads a dashboard image from an HTTP(S) endpoint, displays it on the E-Ink screen, and suspends the Kindle to RAM between updates to conserve battery power.

The dashboard image itself is generated externally. This keeps the Kindle-side software lightweight and lets you use your preferred rendering solution.

For example, you can use [hass-eink-dashboard](https://github.com/cryptomilk/hass-eink-dashboard) to generate E-Ink-optimized dashboard images directly from Home Assistant.

The original project also supports dashboards rendered using tools such as [dashbling](https://github.com/pascalw/dashbling). See the [upstream image generation documentation](https://github.com/pascalw/kindle-dash/blob/main/docs/tipstricks.md#producing-dashboard-images-from-a-webpage).

## Features

### Original Kindle Dash features

- Low-power dashboard display on E-Ink Kindle devices
- Periodic image downloads over HTTP(S)
- Configurable refresh intervals using cron expressions
- Suspend-to-RAM between updates
- Full and partial E-Ink screen refreshes
- KUAL launcher support
- Lightweight operation without a full web browser

### Additional features in this fork

- Optional battery percentage reporting to Home Assistant
- Battery reporting via HTTP webhook (JSON)
- Configurable dashboard PNG URL
- Diagnostic logging for dashboard downloads and battery reporting
- `xh --ignore-stdin` compatibility fix for background execution through KUAL
- No MQTT broker, Python installation, n8n workflow, or additional container required
- Battery reporting can be disabled simply by leaving the webhook URL empty

The battery reporting extension is designed to work with the existing dashboard refresh and suspend cycle.

## Prerequisites

- A jailbroken Kindle with Wi-Fi configured
- SSH access to the Kindle, for example via [USBNetwork](https://wiki.mobileread.com/wiki/USBNetwork) or KOReader
- Kindle Dash and its bundled HTTP client
- A server providing a dashboard image over HTTP(S)

For Home Assistant battery reporting, you additionally need:

- A running Home Assistant instance
- A Number helper for the battery percentage
- A Home Assistant webhook automation

The underlying project was developed and tested primarily for the **Kindle 4 Non-Touch (K4 NT)**. Other Kindle models may require adjustments.

## Installation

### 1. Download Kindle Dash

Use a compatible compiled release from the [original Kindle Dash releases](https://github.com/pascalw/kindle-dash/releases).

**Important:** Until this fork publishes its own compiled release, the upstream release is the base installation. Downloading this fork's source ZIP alone does not provide a complete compiled Kindle package.

### 2. Configure the dashboard

Edit the `local/env.sh` configuration file.

For an externally generated dashboard image:

```sh
export DASHBOARD_URL="http://YOUR_SERVER/dashboard.png"
```

For a Home Assistant E-Ink dashboard, the URL may look like:

```sh
export DASHBOARD_URL="http://HOME_ASSISTANT_IP:8123/api/eink_dashboard/ENTRY_ID/image.png"
```

The configured endpoint must return a dashboard image directly rather than a regular Home Assistant webpage.

### 3. Optional: Enable Home Assistant battery reporting

Add the following to `local/env.sh`:

```sh
export BATTERY_WEBHOOK_URL="http://HOME_ASSISTANT_IP:8123/api/webhook/YOUR_PRIVATE_WEBHOOK_ID"
```

If `BATTERY_WEBHOOK_URL` is empty, no battery reporting request is sent.

For the Home Assistant helper, automation YAML, Kindle script configuration and troubleshooting, see:

**[Home Assistant Battery Reporting Guide](docs/home-assistant-battery.md)**

Keep your actual webhook ID private. Never commit production credentials or private configuration values to GitHub.

### 4. Copy files to the Kindle

Copy the compiled release to:

```text
/mnt/us/dashboard/
```

For example:

```sh
rsync -rtv --no-owner --no-group --no-perms \
  ./ root@KINDLE_IP:/mnt/us/dashboard/
```

The `--no-owner`, `--no-group`, and `--no-perms` options avoid ownership and permission errors on the Kindle's FAT-based user storage.

If SSH uses a custom port:

```sh
rsync -rtv --no-owner --no-group --no-perms \
  -e "ssh -p 2222" \
  ./ root@KINDLE_IP:/mnt/us/dashboard/
```

To enable this fork's additional features on an existing installation, install the modified `fetch-dashboard.sh` and the corresponding `env.sh` configuration from this fork into:

```text
/mnt/us/dashboard/local/
```

Preserve any existing private configuration values when updating.

### 5. Start the dashboard

Connect over SSH and run:

```sh
/mnt/us/dashboard/start.sh
```

Alternatively, launch the dashboard through KUAL.

The Kindle normally enters suspend approximately 10–15 seconds after the refresh process, depending on the configuration and network conditions.

The E-Ink image remains visible during suspend.

## Home Assistant battery reporting

Battery reporting is entirely optional.

When enabled, the Kindle reads its battery percentage with:

```sh
gasgauge-info -c
```

It then sends the value as JSON to a Home Assistant webhook:

```json
{
  "battery": 85
}
```

A Home Assistant automation receives the value and stores it in a Number helper, for example:

```text
input_number.kindle4_battery
```

The battery value can then be displayed on a Home Assistant dashboard, stored in History, or used in automations.

### Reporting workflow

```text
Kindle wakes up
       |
       v
Connect to Wi-Fi
       |
       v
Download dashboard PNG
       |
       v
Read battery percentage
       |
       v
POST battery to Home Assistant webhook
       |
       v
Refresh E-Ink screen
       |
       v
Suspend until next update
```

### Why `--ignore-stdin` matters

When Kindle Dash is launched through KUAL, it runs in the background.

Without `--ignore-stdin`, the bundled `xh` HTTP client may interpret its standard input as an additional request body, causing the following error:

```text
Request body (from stdin) and request data
(key=value) cannot be mixed.
```

The modified scripts in this fork use:

```sh
xh --ignore-stdin
```

for the relevant HTTP requests.

This prevents the standard-input conflict encountered during background execution.

### Logging

When started normally, Kindle Dash writes its output to:

```text
/mnt/us/dashboard/logs/dash.log
```

Example battery-reporting log:

```text
Refreshing dashboard
Wi-Fi connected
Dashboard: Download started
Dashboard: PNG downloaded
Battery: Sending 85%
Battery: Webhook sent (85%)
Partial screen refresh
Going to suspend
```

A successful HTTP client return indicates that the request completed without a reported client error. Check the Home Assistant helper or automation trace to verify that the value was actually processed.

## Test without entering suspend

Connect to the Kindle over SSH:

```sh
cd /mnt/us/dashboard
. ./local/env.sh
sh ./local/fetch-dashboard.sh /mnt/us/dashboard/test.png
```

This executes the image download and optional battery reporting once, without starting the main dashboard suspend loop.

To inspect the logs:

```sh
tail -n 50 /mnt/us/dashboard/logs/dash.log
```

## KUAL integration

KUAL (Kindle Unified Application Launcher) allows you to start the dashboard directly from the Kindle interface without an SSH session.

Copy the directory:

```text
KUAL/kindle-dash/
```

to:

```text
/mnt/us/extensions/kindle-dash/
```

The KUAL menu configuration launches:

```text
/mnt/us/dashboard/start.sh
```

Open KUAL and select **Kindle Dashboard** to start the application.

## Upgrading

If you already have a working Kindle Dash installation:

1. Review the upstream and fork changelogs for changes relevant to your installation.
2. Download a compatible compiled release.
3. Back up your customized `local/env.sh` and `local/fetch-dashboard.sh`.
4. Copy the new release files to the Kindle while preserving your local configuration.
5. Apply the modified scripts from this fork when required.
6. Restart the dashboard and check `logs/dash.log`.

For example, to copy a release without overwriting local settings:

```sh
rsync -rtv --no-owner --no-group --no-perms \
  --exclude='local/' \
  ./ root@KINDLE_IP:/mnt/us/dashboard/
```

**Important:** Synchronizing this GitHub fork with upstream does not automatically update the compiled software running on your Kindle.

## How it works

The Kindle Dash application uses scheduled wakeups to refresh the displayed image.

The refresh interval is configured in:

```text
local/env.sh
```

For example:

```sh
export REFRESH_SCHEDULE="*/10 * * * *"
export TIMEZONE="Europe/Berlin"
```

This configures a refresh schedule of approximately every 10 minutes.

Between scheduled updates, the Kindle enters suspend-to-RAM to reduce power consumption. Network and SSH availability may be interrupted during suspend.

## Security

Older Kindle firmware uses outdated system components and SSH implementations.

Recommended precautions:

- Keep the Kindle in a trusted local network.
- Never expose Kindle SSH directly to the internet.
- Use SSH keys where possible.
- Keep Home Assistant webhook IDs private.
- Do not commit actual webhook URLs containing secret identifiers.
- Prefer restricted network access for Home Assistant endpoints.
- Verify reverse-proxy behavior if Home Assistant webhooks use `local_only: true`.

Webhook URLs containing private identifiers should be treated as credentials.

## Troubleshooting

| Problem | Possible solution |
|---|---|
| Dashboard displays but battery does not update | Check `logs/dash.log` and the Home Assistant automation trace |
| `xh` reports mixed stdin and request data | Ensure `--ignore-stdin` is used |
| Webhook URL missing | Verify `BATTERY_WEBHOOK_URL` is exported in `local/env.sh` |
| HTTP request succeeds but helper does not update | Check the Home Assistant automation, conditions and helper entity |
| SSH is unreachable | The Kindle may be suspended; wake it first |
| `rsync` reports `chown: Operation not permitted` | Use `--no-owner --no-group --no-perms` |
| KUAL does not show the extension | Verify `/mnt/us/extensions/kindle-dash/menu.json` |

## Project status

This repository is a community-maintained fork of the original Kindle Dash project.

The Home Assistant battery reporting extension has been developed and tested for the Kindle 4 Non-Touch using the existing Kindle Dash software.

Compatibility with other Kindle models, firmware versions and dashboard-rendering services has not been comprehensively tested.

This fork is not an official upstream release.

## Credits and attribution

### Original project

**[pascalw/kindle-dash](https://github.com/pascalw/kindle-dash)**

Created by **Pascal Widdershoven**.

The original Kindle Dash software, its low-power scheduling approach, KUAL integration and core functionality originate from this project.

The original project is distributed under the **MIT License**. Its existing copyright and license notices are preserved in the [LICENSE](LICENSE) file.

### This fork

**[bigshit11elf/kindle-dash-battery](https://github.com/bigshit11elf/kindle-dash-battery)**

This fork adds optional Home Assistant battery reporting, configurable integration settings, HTTP client compatibility adjustments and accompanying documentation.

These changes are independently maintained and are not represented as official upstream modifications.

### Additional projects and inspiration

Thanks to [davidhampgonsalves/life-dashboard](https://github.com/davidhampgonsalves/life-dashboard) for the original inspiration, as acknowledged by the upstream project.

Related projects:

- [cryptomilk/hass-eink-dashboard](https://github.com/cryptomilk/hass-eink-dashboard) – Home Assistant E-Ink image rendering
- [pascalw/dashbling](https://github.com/pascalw/dashbling) – Dashboard rendering used by the original project
- [Home Assistant](https://www.home-assistant.io/) – Home automation platform

## License

This project is based on `pascalw/kindle-dash` and continues to distribute the original code under its **MIT License**.

See [LICENSE](LICENSE) for the full license text and original copyright notice.

Contributions in this fork do not remove or replace the rights or attribution of the original author.
