<!--
SPDX-FileCopyrightText: 2026 Masatoshi Nishiguchi

SPDX-License-Identifier: Apache-2.0
-->

# ADR 2026-04-24: Use `serial_dist` for a two-ESP32 distributed Erlang demo

## Status

Accepted

## Context

This repository already contains a small AtomVM sample that separates application startup, distributed Erlang setup, provisioning, Wi-Fi handling, and NVS access into focused modules.

We want to add a serial distributed Erlang example with the same small-module style. The immediate goal is a two-device demo that proves AtomVM `release-0.7` serial distributed Erlang works between two ESP32 boards over a direct UART link.

The first success criterion is simple cross-node message passing between named processes. A small visible reaction such as LED control or an extra log line may be added later.

For this work, the `release-0.7` AtomVM documentation is the source of truth. That documentation explicitly describes serial distribution as a first-class transport using `serial_dist`, longnames, and UART options passed through `net_kernel:start/2`.

Several design questions need to be fixed early:

- should the demo use AtomVM's built-in serial carrier or a custom UART protocol
- should the first proof use message passing or `erpc`
- how should node identity be assigned across two reflashed boards
- how should the implementation be split into modules

## Decision

This project adopts the following architecture for the first serial distributed Erlang demo.

1. Use AtomVM's built-in `serial_dist` transport over one dedicated UART link between two ESP32 boards.
2. Treat the UART used by `serial_dist` as owned by the distribution carrier, not as a shared application UART.
3. Use longnames with the `@serial.local` suffix.
4. Resolve node identity in this order:
   - environment override
   - NVS alias
   - hardware-derived fallback
5. Persist only the human-friendly alias in NVS and compute the full node name at boot.
6. Keep the first protocol limited to registered-process message passing with a small ping/pong exchange.
7. Keep the implementation modular and aligned with the existing repository structure.

The initial transport and naming shape is:

- one direct UART link
- `name_domain: :longnames`
- `proto_dist: :serial_dist`
- `avm_dist_opts.uart_opts`
- `avm_dist_opts.uart_module`
- node names such as `a@serial.local` and `b@serial.local`

The wiring is:

- Board A TX -> Board B RX
- Board A RX -> Board B TX
- Board A GND -> Board B GND

Each board remains connected to the host by its own USB cable for flashing, power, and logs.

The implementation should follow this module split:

- `SampleApp`
  application entry point
- `SampleApp.DeviceIdentity`
  resolves alias from env, NVS, or fallback and builds the final node name
- `SampleApp.SerialDist`
  starts `net_kernel`, configures serial distribution, and registers the demo process
- `SampleApp.DemoNode`
  receives demo messages and replies
- `SampleApp.NVS`
  reused for alias persistence

The initial demo protocol is:

- `{:ping, from}`
- `{:pong, from_node}`
- `{:hello, from_node}`
- `{:set_led, :on | :off}`

The first distributed behavior is registered-process ping/pong:

- Node A sends `{:ping, self()}` to `{:demo, :"b@serial.local"}`
- Node B receives it and replies with `{:pong, node()}`

## Rationale

This keeps the demo focused on proving AtomVM serial distribution, not on inventing a transport or designing a richer protocol too early.

Using `serial_dist` directly follows the upstream `release-0.7` documentation and stays close to the documented quick-start model. That reduces bring-up risk and avoids unnecessary work on framing, validation, and link management that AtomVM already provides.

Registered-process ping/pong is the right first milestone because it demonstrates the most basic distributed behavior with the fewest moving parts. It is easier to explain and verify than starting with `erpc`.

The env -> NVS -> fallback identity order keeps development simple while leaving a path toward a single firmware image that can still acquire stable per-device names.

Keeping the implementation split into focused modules matches the existing repository style and should make the serial demo easier to evolve without over-abstracting it.

## Consequences

### Positive

- Keeps the first demo small and easy to explain
- Reuses AtomVM's supported serial distribution path instead of a custom protocol
- Aligns with the repository's existing modular structure and NVS pattern
- Makes reflashing and per-device naming practical
- Gives a clear first success signal through ping/pong and logs

### Negative

- The UART used for `serial_dist` cannot also be treated as a normal application serial channel
- The first version is intentionally limited to a peer-to-peer, two-device setup
- Human-friendly identity depends on environment or NVS provisioning until hardware fallback is implemented
- `erpc`, monitoring, and richer demo behavior remain deferred

## Rejected alternatives

### Alternative 1: implement a custom UART protocol

Rejected.

This would add protocol design, framing, validation, and troubleshooting work that AtomVM already handles in `serial_dist`.

### Alternative 2: start with `erpc` as the first proof

Rejected for the initial milestone.

`erpc` remains useful, especially for host-driven diagnostics, but registered-process messaging is a simpler first proof for device-to-device bring-up.

### Alternative 3: persist the full node name in NVS

Rejected.

Persisting only the alias keeps the stored value smaller and keeps node naming flexible if the suffix or fallback policy changes later.

## Follow-up implications

- Boot flow should resolve node identity before starting serial distribution.
- Logging should include resolved alias, full node name, UART configuration, startup outcome, received messages, and replies.
- The first implementation should target these milestones:
  - two boards boot with distinct node names
  - one node sends to the peer's registered process
  - the peer replies and the sender logs the response
  - one visible reaction can be added after ping/pong works
  - hardcoded names can later be replaced with env and NVS alias resolution
- Future ADRs may be needed if this grows beyond a two-node UART demo, adds host-driven diagnostics as a first-class path, or changes node identity rules.

## References

- AtomVM `release-0.7` distributed Erlang documentation: https://doc.atomvm.org/release-0.7/distributed-erlang.html
