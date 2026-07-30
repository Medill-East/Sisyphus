# Godot AI / MCP Workflow

This project has two Godot editor addons installed:

- `addons/godot_ai` from `hi-godot/godot-ai` v2.4.2.
- `addons/godot_mcp` from the public `youichi-uda/godot-mcp-pro` addon v1.13.0.

## Godot AI

Godot AI is the active Codex MCP path.

1. Open this project in Godot 4.6.2.
2. Confirm `Project > Project Settings > Plugins > Godot AI` is enabled.
3. The plugin starts/reuses the local MCP server at `http://127.0.0.1:8000/mcp`.
4. Codex is configured in `/Users/haodong/.codex/config.toml`:

```toml
[mcp_servers."godot-ai"]
url = "http://127.0.0.1:8000/mcp"
enabled = true
```

Restart Codex after the server is running so the `godot-ai` MCP tools appear in the tool list.

## Godot MCP Pro

The public repository only contains the Godot editor addon. The MCP server required by Codex/Claude is distributed in the paid full package.

When the paid package is available, use this setup:

```bash
cd /path/to/godot-mcp-pro/server
npm install
npm run build
```

Then add the server to the MCP client config, replacing the path:

```json
{
  "mcpServers": {
    "godot-mcp-pro": {
      "command": "node",
      "args": ["/path/to/godot-mcp-pro/server/build/index.js"],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    }
  }
}
```

The Godot addon listens on WebSocket port `6505`.

## Memory Candidate

If a future Codex agent can write to the user's global memory, preserve this operational note:

```markdown
For `/Users/haodong/Documents/GitHub/Sisyphus`, use Godot 4.6.2/GDScript as the main project and treat `prototype/` as reference only. Prefer Godot AI MCP for editor-aware inspection and scene/node operations: open the Godot project first, confirm the Godot AI dock says `Connected`, then use the Codex MCP server `godot-ai` at `http://127.0.0.1:8000/mcp`. Godot MCP Pro addon is installed, but the full MCP server requires the paid package `server/` path before claiming it is usable. Use Computer Use screenshots for rendered-window validation when MCP tools are unavailable. For gameplay changes, run the Godot tests in `godot/tests` and visually verify push/camera/hand behavior rather than relying only on static code.
```
