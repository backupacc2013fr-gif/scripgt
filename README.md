# Roblox School Fight Combat

Fair, server-controlled combat for an experience you own.

## Features

- Punch hitbox: server radius check with no client damage authority
- Configurable punch speed
- 1.5× stomp damage while airborne and falling
- Player-triggered weave dash
- Hold-to-glide movement
- Server stamina and cooldown checks

## Controls

| Action | Input |
|---|---|
| Punch | F or left mouse |
| Stomp | R |
| Weave dash | Q |
| Hold glide | E |

## Roblox setup

Place the script in `src/ServerScriptService` under `ServerScriptService` and the local script in `src/StarterPlayer/StarterPlayerScripts` under `StarterPlayerScripts`.

The combat remote is created automatically by the server. Never use a client script to grant damage, stamina, or cooldown changes.

## Config

Edit these constants in `CombatServer.server.lua`:

- `PUNCH_DAMAGE`
- `PUNCH_RANGE`
- `PUNCH_COOLDOWN`
- `STOMP_DAMAGE`
- `STOMP_MULTIPLIER`
- `STOMP_RANGE`
- `WEAVE_COOLDOWN`
- `WEAVE_COST`
- `GLIDE_SPEED`
