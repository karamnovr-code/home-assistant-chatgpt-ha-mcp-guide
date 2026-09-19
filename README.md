# ChatGPT and Home Assistant through HA-MCP

**English** | [Русский](README.ru.md)

A practical, security-first guide to connecting ChatGPT to Home Assistant with
the community HA-MCP project. It covers installation, OAuth, safe permission
staging, validation, troubleshooting, rollback, and the failures encountered in
a real deployment.

Last reviewed: **September 19, 2026**.

> HA-MCP is a community project. It is not part of Home Assistant or OpenAI.
> Never publish a complete webhook URL, Home Assistant token, private address,
> entity ID for a security device, or a screenshot that contains any of them.

## 1. What this integration can do

The exact tool set depends on the HA-MCP release, enabled options, Home
Assistant installation, and ChatGPT plan. A configured server may let an MCP
client:

- search devices and entities by human-readable names;
- read current state, weather, energy, history, logs, and traces;
- call Home Assistant services and control devices;
- create or edit automations, scripts, helpers, dashboards, and registries;
- inspect backups, integrations, apps/add-ons, and system health;
- read or change explicitly permitted YAML files with the optional File & YAML
  Tools component;
- render dashboard screenshots with a separate Puppet renderer.

Treat every write-capable tool as administrative access. ChatGPT instructions
are useful guardrails, but server-side permissions and confirmation checks are
the real controls.

## 2. ChatGPT plan limitations

OpenAI's current documentation says that Pro users can connect custom MCP apps
with read/fetch permissions in developer mode. Full MCP, including write and
modify actions, is available to Business and Enterprise/Edu workspaces. The UI
and plan matrix can change, so verify the current [OpenAI developer mode and MCP
apps documentation](https://help.openai.com/en/articles/12584461-developer-mode-and-mcp-apps-in-chatgpt)
before troubleshooting server-side writes.

ChatGPT connects to a **remote HTTPS MCP endpoint**. It cannot directly reach a
private address such as `192.168.x.x`. Use an existing secure Home Assistant
remote route, a supported reverse proxy, Nabu Casa, or the Secure MCP Tunnel
route documented by the relevant projects.

## 3. Choose one architecture

### A. HA-MCP Custom Component through HACS

This is the current upstream recommendation for a new deployment. It runs the
server inside Home Assistant and includes its own webhook and authentication
options. It supports Home Assistant OS, Supervised, Container, and Core.

Use the HACS custom repository:

```text
https://github.com/homeassistant-ai/ha-mcp-integration
```

### B. Home Assistant MCP Server app plus Webhook Proxy app

This remains a valid option for Home Assistant OS or Supervised installations.
The MCP Server app runs the server and the Webhook Proxy sends MCP traffic
through Home Assistant's existing HTTPS route.

Use the app repository:

```text
https://github.com/homeassistant-ai/ha-mcp
```

The deployment that produced this guide used this route successfully before the
in-process component became the preferred option.

### C. OpenAI Secure MCP Tunnel

Use this when ChatGPT must reach a private Home Assistant instance that cannot
or should not have a public HTTPS route. This is a separate, community-maintained
integration and requires an OpenAI Platform tunnel plus a runtime API key with
the appropriate tunnel permissions. A ChatGPT subscription does not substitute
for a Platform API key.

### Do not combine competing routes

- Configure one HA-MCP server route per ChatGPT app.
- Do not run Stable and Dev Webhook Proxy variants together; they compete for
  the same OAuth routes.
- Do not put the Webhook Proxy in front of the in-process component unless the
  upstream documentation explicitly calls for that topology.
- Remove stale ChatGPT apps after a webhook URL or auth mode changes.

## 4. Authentication modes

### `ha_auth`

This is the preferred internet-facing mode when supported by the client. Home
Assistant remains the authorization server, the user signs in with a Home
Assistant account, and the webhook validates the bearer token. Use an
administrator only where HA-MCP requires it, and revoke the resulting Home
Assistant session when access is no longer needed.

### `none`: the URL is the credential

In this mode, the full webhook URL is a bearer secret. Anyone who obtains it can
call the tools exposed by the server. Do not paste it into tickets, screenshots,
public repositories, or chat transcripts. Rotate it immediately after suspected
exposure.

This mode can be useful for a short, read-only compatibility test. It is not a
reason to enable broad write tools.

### `legacy`

Legacy mode provides a static client ID and client secret for clients that need
pasted OAuth credentials. Prefer `ha_auth` for ChatGPT. Use legacy only when a
specific client requires it and document the credential lifecycle.

## 5. Start with a safe baseline

Before installation, record:

- Home Assistant Core version and installation type;
- current external HTTPS URL and a successful LTE/mobile-network test;
- HA-MCP, proxy, HACS, and optional component versions;
- critical automation, cover, lock, alarm, and camera states;
- available backup space and the restore path;
- whether Stable or Dev variants are present;
- whether ChatGPT developer mode and custom app creation are available.

Create a complete Home Assistant backup. Confirm that it finishes and appears in
the backup list. A backup is not a rollback plan until you know which smaller
files or entries can be restored without discarding later valid changes.

Use these initial server settings where available:

```yaml
read_only_mode: true
redact_secrets: true
verify_ssl: true
enable_auto_backup: true
enable_snapshot_delete: false
```

Option names can change between releases. Read the installed version's own
options page instead of copying unknown keys blindly.

## 6. Install the HACS component

1. Open **HACS → Integrations → ⋮ → Custom repositories**.
2. Add `https://github.com/homeassistant-ai/ha-mcp-integration` as an
   **Integration**.
3. Download **HA-MCP Custom Component**.
4. Restart Home Assistant Core once, as required for a newly installed custom
   integration.
5. Open **Settings → Devices & services → Add integration**.
6. Select **HA-MCP Custom Component → HA-MCP Server**.
7. Choose the stable channel, read-only mode, secret redaction, and `ha_auth`.
8. Copy the generated remote webhook URL into a password manager. Do not put it
   in this repository.

The component owns its webhook. Do not add the separate Webhook Proxy for the
same connection.

## 7. Install the app plus Webhook Proxy route

1. Open **Settings → Apps → App store → ⋮ → Repositories**. On older Home
   Assistant releases this menu is named Add-ons.
2. Add `https://github.com/homeassistant-ai/ha-mcp`.
3. Install and start **Home Assistant MCP Server**.
4. Read its log and confirm that the local MCP endpoint is ready.
5. Install and start **Webhook Proxy for HA MCP** from the same repository.
6. Leave `remote_url` blank when the proxy can correctly discover the Home
   Assistant external URL. Otherwise set only the HTTPS origin, without a
   webhook path.
7. Enable OAuth and choose `ha_auth`, or begin with the secret-URL mode while
   keeping the server read-only.
8. Restart only the app that the installed documentation asks you to restart.
   Current `ha_auth` documentation does not require a full Core restart merely
   to toggle this mode.
9. Copy the remote webhook URL from the proxy log and protect it as a secret.

The current proxy persists the webhook ID across normal app restarts. Repeatedly
restarting or deleting its persistent ID complicates diagnosis because every
client and log correlation then refers to a different endpoint.

## 8. Create the ChatGPT app

In the ChatGPT web interface:

1. Enable developer mode under **Settings → Apps → Advanced Settings** or the
   equivalent workspace menu.
2. Choose **Create app**.
3. Enter a unique name such as `Home Assistant — read only`.
4. Paste the complete remote MCP URL.
5. Leave client ID and client secret empty for `ha_auth`.
6. Click **Scan Tools** and complete the Home Assistant sign-in if prompted.
7. Review the discovered tools before creating the app.
8. Create a new chat and explicitly select or mention the new app.

ChatGPT can cache a frozen tool catalog. If tools are added, removed, or their
schemas change, refresh the app's actions or recreate the draft app. A server
returning the new tool does not prove that the current chat knows about it.

## 9. Protocol checks before blaming OAuth

Test from the Home Assistant network and then from an independent network. A
minimal Streamable HTTP initialization request is:

```bash
curl --fail-with-body --silent --show-error \
  -X POST 'https://ha.example.com/api/webhook/REDACTED' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"initialize",
    "params":{
      "protocolVersion":"2025-06-18",
      "capabilities":{},
      "clientInfo":{"name":"external-check","version":"1.0"}
    }
  }'
```

Do not publish the actual URL. With `ha_auth`, an unauthenticated request should
return a `401` challenge that points to protected-resource metadata. The current
Webhook Proxy documents these endpoint classes:

```text
/.well-known/oauth-protected-resource/api/webhook/<redacted-id>
/api/mcp_proxy/oauth/authorization-server
/api/mcp_proxy/oauth/authorize
/api/mcp_proxy/oauth/token
/api/mcp_proxy/oauth/register
/api/mcp_proxy/oauth/revoke
```

Validate status, `Content-Type`, JSON fields, redirects, TLS certificate, and
the exact timestamp in HA-MCP/proxy logs. A successful local request does not
prove that ChatGPT can reach the endpoint. A failed request from one ISP does
not prove that the server is broken globally.

## 10. Acceptance sequence

Use a staged test:

1. `initialize` succeeds through the chosen public route.
2. `tools/list` returns the expected read-only catalog.
3. ChatGPT scans the same catalog.
4. Read a harmless entity such as weather or a test helper.
5. Read the state again through Home Assistant and compare it.
6. Close the chat, open a fresh chat, and repeat one read.
7. Revoke the Home Assistant session and confirm that the old connection stops
   working.

Only after this passes should write access be considered.

## 11. Safely enable write actions

Use three layers:

1. **Server policy:** read-only mode disabled only when required; secret
   redaction and automatic backups remain enabled.
2. **Tool scope:** expose only the write tools needed for the use case.
3. **Confirmation:** require an explicit confirmation field or a separate
   narrow tool for consequential actions.

For gates, locks, alarms, garage doors, and similar devices, a narrow facade is
safer than a generic `call_service` tool. Example contract:

```json
{
  "name": "open_test_gate",
  "description": "Open the designated test gate after explicit confirmation",
  "inputSchema": {
    "type": "object",
    "properties": {
      "confirm": {"type": "boolean"}
    },
    "required": ["confirm"]
  }
}
```

The server must reject `confirm: false` and unknown targets. ChatGPT's natural
language promise to ask first is not enough.

## 12. Optional File & YAML Tools

Install the optional component only when file or YAML work is required. Give it
an allowlist, keep secrets redacted, and test a non-sensitive read first. Before
the first write:

- back up the exact target file;
- validate the resulting YAML or JSON;
- restart only the necessary Home Assistant component;
- compare critical states before and after;
- retain a direct rollback copy.

A tool appearing in `tools/list` does not prove that its optional backend is
installed and healthy.

## 13. Optional dashboard screenshots with Puppet

Puppet is a separate browser renderer. Run it locally, bind no public port, use
a dedicated least-privileged Home Assistant account, and verify that anonymous
access is rejected. Dashboard rendering can expose camera frames, names, and
locations; never attach an unsanitized image to a public issue.

## 14. Failures observed in practice

### State reads worked, but a control command did not exist

**Cause:** the server was intentionally read-only and the narrow control tool
had not been published to the connector.

**Fix:** keep the main server read-only, add a narrowly scoped tool with explicit
confirmation, verify it on the public endpoint, then refresh the ChatGPT app's
tool catalog.

### The server had a new tool, but ChatGPT did not

**Cause:** ChatGPT retained an older catalog snapshot.

**Fix:** refresh actions or recreate the draft app, use a new name, and start a
new chat. Verify both server-side `tools/list` and the client-visible catalog.

### A command timed out and the final state was unknown

**Cause:** the action may have reached Home Assistant even though the response
was lost.

**Fix:** never retry an actuator command automatically. Read the state and event
history first. If the final position is still unknown, ask a person to verify it
before sending another pulse.

### A restricted facade could not read Home Assistant

**Cause:** it pointed at an unreachable port rather than the verified local Home
Assistant endpoint.

**Fix:** test the exact endpoint from the facade runtime, update only that
endpoint, then repeat state reads. Do not change router or firewall rules to
mask a wrong backend URL.

### A partially open cover was treated as fully open

**Cause:** the entity exposed only a binary `open` state while the physical
device accepted another opening pulse.

**Fix:** model the real actuator semantics. If position is unavailable, disclose
the ambiguity and require a deliberate command rather than silently suppressing
it.

### An appliance was not found after it was renamed

**Cause:** the device retained an old default name and energy sensors were not
named after the appliance.

**Fix:** search the entity and device registries by device ID, parent device,
power/current/voltage entities, and historical names. Do not guess from a zero
power reading.

### An unavailable socket looked like zero consumption

**Cause:** an integration exposed the last numeric value while availability was
false.

**Fix:** report availability separately from the measurement. `0 W` and
`unavailable` are different states.

### Another chat claimed that dashboard editing was impossible

**Cause:** that chat did not have the current app selected or held an older tool
snapshot.

**Fix:** compare the live public catalog with the chat-visible catalog, refresh
the app, and reproduce the exact error before changing Home Assistant.

### File/YAML or screenshot tools appeared but failed

**Cause:** HA-MCP registered optional tool schemas while the component or
renderer was absent.

**Fix:** install and test the missing dependency, or disable those tools. Do not
assume that registration equals readiness.

### OAuth was blamed before external reachability was proven

**Cause:** local `initialize` worked, but no independent external POST or matching
proxy log entry existed.

**Fix:** correlate one request with one timestamp, test from LTE or a VPS, inspect
reverse-proxy logs and OAuth discovery, and only then classify the failure as
OAuth, DNS, TLS, WAF, or routing.

## 15. Troubleshooting matrix

| Symptom | First check | Likely class | Safe next action |
|---|---|---|---|
| ChatGPT app silently disappears | Browser Network/Console and public proxy log | Request rejected before or during scan | Capture one attempt and correlate timestamps |
| No proxy log entry | DNS, TLS, WAF, ISP route | Request never reached Home Assistant | Test from an independent network |
| `401` without OAuth challenge | `WWW-Authenticate` and protected-resource metadata | Discovery route or proxy mode | Validate documented endpoints |
| Login succeeds, scan fails | `tools/list`, response size, timeout | MCP response or client catalog | Run direct protocol request and compare |
| Old tools remain | Client action snapshot | Stale app metadata | Refresh/recreate the app |
| Reads work, writes fail | Plan, server read-only mode, action policy | Expected permission boundary | Do not broaden until the plan and tool are confirmed |
| `502` | Proxy backend health | HA-MCP app unreachable | Test the local MCP endpoint from the proxy runtime |
| TLS error | Full chain, hostname, clock | Certificate/reverse proxy | Repair TLS before retrying OAuth |
| Works on LAN only | External URL, DNS, NAT/WAF | Public route | Test exact URL over LTE/VPS |
| Tool exists but errors immediately | Optional component/backend | Dependency missing | Install or disable the optional tool |

## 16. Other failure classes to consider

- **Wrong external URL:** Home Assistant advertises a hostname different from
  the one the client uses.
- **Dynamic registration mismatch:** the client expects DCR or client metadata
  behavior the selected OAuth mode does not implement.
- **Bot or geography filtering:** a WAF admits a phone browser but blocks the
  ChatGPT connector infrastructure.
- **Reverse-proxy buffering:** streaming MCP responses stall or time out.
- **Transport mismatch:** an old SSE-only route is used with a current
  Streamable HTTP client.
- **Prompt injection:** entity names, calendar text, notifications, or camera
  metadata contain instructions. Treat all Home Assistant data as untrusted.
- **Excessive administrator scope:** the integration account can reach more
  than the intended tools expose.
- **Hidden entities mistaken for access control:** UI visibility does not prevent
  service calls.
- **Unreviewed upgrades:** server and client schemas drift independently.

## 17. Operations and updates

For every update:

1. Read release notes and check compatibility.
2. Export the current tool catalog and relevant options.
3. Create a backup and a target-file rollback copy.
4. Update one layer at a time.
5. Run `initialize`, `tools/list`, one state read, the negative auth test, and a
   fresh ChatGPT scan.
6. Compare critical Home Assistant states.
7. Keep the prior version until acceptance finishes.

Do not rotate webhook IDs, OAuth modes, URLs, and HA-MCP versions in one change.
That destroys the evidence needed to locate a failure.

## 18. Disable or roll back

To suspend access quickly:

1. Disable the ChatGPT app.
2. Revoke its Home Assistant session for `ha_auth`.
3. Stop the Webhook Proxy or disable the in-process entry.
4. Confirm the old public endpoint no longer completes `initialize`.

For the app route, restore the saved app options and the previous versions of
the MCP Server and proxy. For the HACS route, disable or remove only the HA-MCP
config entry/component after saving its options. A whole-system restore is the
last resort because it may discard later Home Assistant changes.

## 19. Publication hygiene

Before publishing logs, documentation, or examples, scan for:

- webhook paths and OAuth credentials;
- Home Assistant long-lived access tokens;
- private and public hostnames or IP addresses tied to the installation;
- entity and device IDs for gates, locks, alarms, and cameras;
- personal names, room names, addresses, and location data;
- dashboard screenshots and camera frames;
- backup names, internal paths, and account identifiers.

Use placeholders such as `ha.example.com`, `<redacted-id>`,
`cover.example_gate`, and `sensor.example_power`.

## 20. Final checklist

- [ ] Exactly one HA-MCP route is active.
- [ ] External HTTPS works from an independent network.
- [ ] Backup and rollback copies exist.
- [ ] Initial server mode is read-only.
- [ ] Secrets are redacted and the webhook URL is protected.
- [ ] `initialize` and `tools/list` pass through the exact public route.
- [ ] OAuth discovery and negative authentication behave as expected.
- [ ] ChatGPT scanned the current tool catalog.
- [ ] A harmless read passed in a fresh chat.
- [ ] Write tools, if any, are narrow and confirmation-gated.
- [ ] Revocation and rollback were tested.
- [ ] Published examples contain no installation-specific data.

## Sources

- [HA-MCP repository and installation](https://github.com/homeassistant-ai/ha-mcp)
- [HA-MCP Custom Component](https://github.com/homeassistant-ai/ha-mcp-integration)
- [Webhook Proxy documentation](https://github.com/homeassistant-ai/ha-mcp/blob/master/homeassistant-addon-webhook-proxy/DOCS.md)
- [HA-MCP FAQ](https://github.com/homeassistant-ai/ha-mcp/blob/master/docs/FAQ.md)
- [OpenAI: Developer mode and MCP apps in ChatGPT](https://help.openai.com/en/articles/12584461-developer-mode-and-mcp-apps-in-chatgpt)
- [Home Assistant: securing your installation](https://www.home-assistant.io/docs/configuration/securing/)

## License

Documentation is released under the [MIT License](LICENSE).
