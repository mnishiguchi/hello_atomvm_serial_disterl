<!--
SPDX-FileCopyrightText: 2026 piyopiyo.ex members

SPDX-License-Identifier: Apache-2.0
-->

# hello_atomvm_serial

`hello_atomvm_serial` は、ESP32 と AtomVM でシリアル通信を試すためのサンプルです。

既存の serial distributed Erlang と、RS485 / Modbus RTU の実験を独立した動作モードとして収録しています。手元では Seeed Studio XIAO ESP32-C5 を使って検証していますが、ESP32-C5 固有の実装ではありません。

## できること

- 2 台の AtomVM ノードを UART 上の `serial_dist` で接続
- ESP32 の `UART1` から RS485 へ生のバイト列を送受信
- Modbus RTU function `0x03` の request を生成
- Modbus RTU response の CRC16、unit id、register 数を検証して decode
- 接続中の ESP32 variant に合う AtomVM firmware を ExAtomVM から install
- partition table から `main.avm` を見つけて application を flash

## このリポジトリがやらないこと

- Modbus specification 全体の実装
- function `0x03` 以外の function code
- Modbus slave
- `serial_dist` 上での Modbus
- DE / RE pin を application から制御する RS485 half-duplex
- `Circuits.UART` など複数 transport の abstraction
- custom AtomVM firmware の build

## 動作モード

書き込み時の `ATOMVM_EXPERIMENT` で entrypoint を選びます。

| 値 | 用途 |
| --- | --- |
| `serial_dist` | 2 台の AtomVM node 間で ping / pong。既定値 |
| `rs485_echo` | 起動メッセージを送信し、受信した byte 列をそのまま返信 |
| `modbus_rtu` | Modbus RTU function `0x03` で Holding Register を定期的に読む |

```text
serial_dist               rs485_echo / modbus_rtu
    ↓                               ↓
AtomVM :uart              AtomVM :uart (UART1)
    ↓                               ↓
UART                      TTL ↔ RS485 自動方向制御 transceiver
                                    ↓
                               RS485 A / B
```

## 検証環境

- Seeed Studio XIAO ESP32-C5
- AtomVM `v0.7.0-beta.0`
- Elixir `1.17` / Erlang/OTP `27`
- USB data cable
- RS485 実験では 3.3 V logic 対応の自動方向制御 TTL ↔ RS485 transceiver と RS485 peer

これは現在の検証環境であり、対応 board を ESP32-C5 に限定するものではありません。AtomVM / ExAtomVM が対応する別の ESP32 variant でも、board に合わせて UART pin を設定すれば同じ experiment を実行できます。

## AtomVM の install

依存関係を取得します。

```sh
mix deps.get
```

ESP32 board を USB 接続し、AtomVM firmware を install します。

```sh
mix atomvm.esp32.install --version v0.7.0-beta.0
```

この操作は確認後に device の flash を消去します。取得した firmware は `firmware_images/` に cache されます。この directory は disposable な download cache であり、git から除外しています。

application は別に書き込みます。

```sh
mix atomvm.esp32.flash --port /dev/ttyACM0
```

application の flash address は固定していません。現在の ExAtomVM は device の partition table を読み、`main.avm` partition の実際の address を使います。

### Firmware と `atomvm` Hex package

ESP32 上で動く firmware の version は `atomvm.esp32.install --version` で選びます。

`atomvm` Hex package は `mix atomvm.check` が利用する supported-API metadata であり、firmware 本体ではありません。対応する `0.7.0-beta.0` package が Hex にないため、現時点では dependency に追加していません。

## UART 設定

手元の XIAO ESP32-C5 で使っている既定値:

| 項目 | `serial_dist` / `rs485_echo` | `modbus_rtu` |
| --- | --- | --- |
| peripheral | `UART1` | `UART1` |
| TX | D6 / GPIO11 | D6 / GPIO11 |
| RX | D7 / GPIO12 | D7 / GPIO12 |
| speed | 115200 | 9600 |
| data bits | 8 | 8 |
| parity | none | none |
| stop bits | 1 | 1 |
| flow control | none | none |

書き込み時の環境変数で上書きできます。

| 環境変数 | 説明 |
| --- | --- |
| `ATOMVM_UART_PERIPHERAL` | UART peripheral |
| `ATOMVM_UART_SPEED` | baud rate |
| `ATOMVM_UART_TX_PIN` | TX GPIO |
| `ATOMVM_UART_RX_PIN` | RX GPIO |
| `ATOMVM_UART_DATA_BITS` | data bits |
| `ATOMVM_UART_PARITY` | `none`, `even`, `odd` |
| `ATOMVM_UART_STOP_BITS` | stop bits |

これらの値は `config/config.exs` から compile-time configuration に取り込みます。設定値を変更したときは、古い値を残さないように flash 前に `mix clean` を 1 回実行します。`ATOMVM_EXPERIMENT` だけを変更するときは不要です。

別の board では pinout を確認し、`ATOMVM_UART_TX_PIN` と `ATOMVM_UART_RX_PIN` を設定してください。UART peripheral 名も異なる場合は `ATOMVM_UART_PERIPHERAL` で変更できます。

## Raw RS485 echo

Modbus を試す前に、plain byte の送受信だけを確認します。

### 配線

AtomVM の通常の UART API だけで動かすため、自動方向制御 transceiver を使います。DE / RE を GPIO で制御する module は、この実験の対象外です。

| XIAO ESP32-C5 | RS485 transceiver | 方向 |
| --- | --- | --- |
| D6 / GPIO11 | DI / TXD | ESP32 → bus |
| D7 / GPIO12 | RO / RXD | bus → ESP32 |
| GND | GND | common ground |
| 3V3 | VCC | module が 3.3 V 対応の場合のみ |
| — | A | peer の A |
| — | B | peer の B |

5 V 専用 MAX485 module の RO を 3.3 V logic の ESP32 に直結しないでください。MAX3485 / SP3485 系などの 3.3 V transceiver と自動方向制御回路を備えた module を使うか、適切な level conversion を入れます。

長い bus では両端に 120 Ω termination を置き、bias resistor は bus 上の 1 箇所だけにします。製品間で A/B の表記が逆の場合は、A と B を入れ替えて確認します。

### 実行

```sh
export ATOMVM_EXPERIMENT=rs485_echo
mix atomvm.esp32.flash --port /dev/ttyACM0
mix atomvm.esp32.monitor --port /dev/ttyACM0
```

起動時に RS485 側へ `atomvm-rs485-ready\r\n` を 1 回送ります。peer から受信した byte 列は USB console に表示し、同じ内容を RS485 側へ返信します。

```text
rs485_echo: received 5 bytes: "hello"
rs485_echo: echoed 5 bytes
```

この送受信が安定してから Modbus RTU を試します。

## Modbus RTU

master/client 側の function `0x03`、Read Holding Registers だけを実装しています。

```text
SampleApp.Modbus.PDU
    ↓ function 0x03 + address + quantity
SampleApp.Modbus.RTU
    ↓ unit id + CRC16 (low byte first)
SampleApp.Modbus.Transport
    ↓
AtomVM :uart → automatic-direction RS485 transceiver → slave
```

ローカル実装の範囲:

- Modbus CRC16 の計算と検証
- RTU request frame の encode
- normal response と exception response の decode
- unit id と response register 数の検証
- UART から分割して届く response の組み立て

`Circuits.UART` を前提とする serial library は dependency に追加していません。

### 設定

| 環境変数 | 既定値 | 説明 |
| --- | --- | --- |
| `MODBUS_UNIT_ID` | `1` | slave address (`1..247`) |
| `MODBUS_START_ADDRESS` | `0` | 最初の Holding Register address |
| `MODBUS_QUANTITY` | `1` | 読み出す register 数 (`1..125`) |
| `MODBUS_RESPONSE_TIMEOUT_MS` | `1000` | response timeout |
| `MODBUS_REQUEST_INTERVAL_MS` | `5000` | request interval |

9600 8E1 の slave から register を 2 個読む例:

```sh
export ATOMVM_EXPERIMENT=modbus_rtu
export ATOMVM_UART_SPEED=9600
export ATOMVM_UART_PARITY=even
export MODBUS_UNIT_ID=1
export MODBUS_START_ADDRESS=0
export MODBUS_QUANTITY=2

mix clean
mix atomvm.esp32.flash --port /dev/ttyACM0
mix atomvm.esp32.monitor --port /dev/ttyACM0
```

成功時は decode 済みの 16-bit register 値を表示します。

```text
modbus_rtu: registers [10, 258]
```

CRC error、異なる unit id、register 数の不一致、Modbus exception、malformed response は error として表示します。

実配線で function `0x03` が安定して動作した後に、`yamodbus` との再比較、transport abstraction、AtomVM UART backend の upstream 提案を検討します。

## Serial distributed Erlang

`serial_dist` は既定の動作モードです。既定の pin 設定では 2 台の XIAO ESP32-C5 を次のように接続します。

- Board A D6 / GPIO11 → Board B D7 / GPIO12
- Board A D7 / GPIO12 ← Board B D6 / GPIO11
- Board A GND ↔ Board B GND

RS485 transceiver は使いません。別の ESP32 board を使う場合は、それぞれの pinout に合わせて TX / RX を選びます。

Board A:

```sh
export ATOMVM_EXPERIMENT=serial_dist
export ATOMVM_NODE_ALIAS=a
export ATOMVM_PEER_ALIAS=b
unset ATOMVM_AUTO_PING

mix clean
mix atomvm.esp32.flash --port /dev/ttyACM0
```

Board B:

```sh
export ATOMVM_EXPERIMENT=serial_dist
export ATOMVM_NODE_ALIAS=b
export ATOMVM_PEER_ALIAS=a
export ATOMVM_AUTO_PING=true

mix clean
mix atomvm.esp32.flash --port /dev/ttyACM1
```

追加設定:

| 環境変数 | 既定値 | 説明 |
| --- | --- | --- |
| `ATOMVM_NODE_ALIAS` | `a` | local node alias |
| `ATOMVM_PEER_ALIAS` | `b` または `a` | peer node alias |
| `ATOMVM_AUTO_PING` | false | truthy 値なら起動後に ping |
| `ATOMVM_PING_DELAY_MS` | `1000` | auto ping delay |

## テスト

protocol layer は通常の BEAM 上でテストできます。

```sh
mix format --check-formatted
mix test
```

テストには標準的な request vector `01 03 00 00 00 0A C5 CD`、CRC failure、exception response、複数 register の decode、response length の判定を含みます。

Seeed Studio XIAO ESP32-C5 実機では次を確認しています。

- AtomVM `v0.7.0-beta.0` の install と起動
- partition table からの `main.avm` 検出と application flash
- `serial_dist` の起動
- `rs485_echo` の UART open と起動 message の送信
- `modbus_rtu` の function `0x03` request 送信

RS485 A/B bus 上の bidirectional echo と Modbus slave response は、transceiver と peer を接続した状態で確認してください。

## 設計判断

長期的な設計判断は [`docs/adr`](docs/adr/README.md) に記録しています。

調査中に分かったことや実機検証の範囲は [`docs/worklog`](docs/worklog/README.md) に記録しています。

## 参考資料

- [AtomVM release-0.7 UART guide](https://doc.atomvm.org/release-0.7/programmers-guide.html#uart)
- [ExAtomVM](https://github.com/atomvm/exatomvm)
- [Seeed Studio XIAO ESP32-C5 getting started guide](https://wiki.seeedstudio.com/xiao_esp32c5_getting_started/)
