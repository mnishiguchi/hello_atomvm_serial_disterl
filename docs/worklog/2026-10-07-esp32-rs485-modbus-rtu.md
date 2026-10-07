# 2026-10-07: ESP32 UART / RS485 / Modbus RTU の初期実装

## 目的

既存の `serial_dist` を保ったまま、AtomVM の通常の UART API を使って次の経路を試せるようにする。

```text
AtomVM → ESP32 UART → 自動方向制御 RS485 transceiver → Modbus RTU slave
```

## 検証環境

- Seeed Studio XIAO ESP32-C5
- AtomVM `v0.7.0-beta.0`
- Elixir `1.17.3` / Erlang/OTP `27`
- ExAtomVM の `mix atomvm.esp32.install` と `mix atomvm.esp32.flash`
- USB device: `/dev/ttyACM0`

ESP32-C5 はこのとき手元にあった検証 device であり、実装上の必須条件ではない。別の AtomVM / ExAtomVM 対応 ESP32 board では UART peripheral と GPIO を board の pinout に合わせる。

## 分かったこと

### Firmware の管理

- AtomVM firmware image を repository に置く必要はない
- `mix atomvm.esp32.install --version v0.7.0-beta.0` は接続 device の variant に合う firmware を選ぶ
- download された `firmware_images/` は cache なので git から除外する
- `mix atomvm.esp32.flash` は partition table から `main.avm` partition を検出できる
- application の flash offset を project 側で固定する必要はない

`atomvm` Hex package は supported-API metadata 用であり、ESP32 firmware を install する package ではない。対応する beta package が利用できない段階では dependency に追加せず、firmware version は install command で明示する。

### XIAO ESP32-C5 の UART pin

XIAO ESP32-C5 の header で UART と表示されている pin は次の通り。

| signal | XIAO pin | GPIO |
| --- | --- | --- |
| TX | D6 | GPIO11 |
| RX | D7 | GPIO12 |

この組み合わせを repository の既定値にした。別の board では `ATOMVM_UART_TX_PIN` と `ATOMVM_UART_RX_PIN` で変更する。

### RS485 transport

AtomVM の `:uart` は通常の UART operation を提供するが、ESP-IDF の native RS485 half-duplex mode は公開していない。そのため、最初の実験では DE / RE timing を hardware 側で処理する自動方向制御 transceiver を使う。

`rs485_echo` は UART を開き、起動 message を送信し、受信 byte 列をそのまま返信する。Modbus framing に進む前に UART と transceiver の経路だけを確認できる。

### Minimal Modbus RTU

`Circuits.UART` を前提とする library 全体は導入せず、function `0x03` に必要な範囲だけを実装した。

- Modbus CRC16 の計算と検証
- Read Holding Registers request の encode
- normal response と exception response の decode
- unit id と register 数の検証
- UART から分割して届く response の組み立て

protocol layer と AtomVM UART transport を分けたため、frame 処理は通常の BEAM 上でテストできる。

## 実機で確認したこと

- AtomVM `v0.7.0-beta.0` の install と起動
- partition table からの `main.avm` 検出と application flash
- `serial_dist` mode の起動
- `rs485_echo` mode での UART open と起動 message の送信
- `modbus_rtu` mode での function `0x03` request の送信
- host 上の protocol test: 14 tests, 0 failures

## 未確認のこと

次の項目には transceiver と実際の peer / Modbus slave が必要なので、この時点では未確認。

- RS485 A/B bus 上での bidirectional echo
- 実 slave から返る function `0x03` response の受信と decode
- 長時間または連続 request 時の安定性
- termination と bias を含む実際の bus topology

## 次に試すこと

1. XIAO ESP32-C5 の D6 / D7 に 3.3 V 対応の自動方向制御 transceiver を接続する
2. `rs485_echo` で双方向の plain byte 通信を確認する
3. Modbus slave の UART 設定に baud rate、parity、stop bits を合わせる
4. function `0x03` で既知の Holding Register を読み、期待値と照合する
5. 実機検証後に `yamodbus` との再比較や transport abstraction の必要性を判断する

長期的な設計判断は [ADR 0002](../adr/0002-自動方向制御rs485と最小modbus実装を使う.md)、現在の実行手順と配線は [README](../../README.md) を参照する。
