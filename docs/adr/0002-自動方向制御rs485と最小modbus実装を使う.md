# 0002: 自動方向制御 RS485 と最小 Modbus 実装を使う

## 状態

採用

## 背景

AtomVM を実行する ESP32 から RS485 上の Modbus RTU slave に接続したい。現在の検証 board は Seeed Studio XIAO ESP32-C5 だが、設計を ESP32-C5 固有にはしない。

AtomVM は通常の UART API を提供するが、ESP-IDF の native RS485 half-duplex mode は公開していない。また、既存の Elixir Modbus library の多くは Linux / Nerves 向けの `Circuits.UART` を前提としている。

## 決定

- 3.3 V logic 対応の自動方向制御 TTL ↔ RS485 transceiver を使用する
- 最初に plain byte の echo で RS485 path を確認する
- Modbus は function `0x03` に必要な PDU、RTU framing、CRC16、response decode だけをローカル実装する
- UART access は AtomVM の `:uart` module を直接使用する
- `serial_dist` と RS485 / Modbus RTU は独立した動作モードにする

## 理由

自動方向制御 transceiver を使えば、AtomVM application から DE / RE timing を管理せずに通常の UART として扱える。

小さな protocol layer だけを実装することで、`Circuits.UART` dependency や不要な Modbus feature を持ち込まず、ESP32 上で検証したい経路へ集中できる。

## 影響

- DE / RE を application から制御する transceiver は対象外になる
- 対応する Modbus function code は `0x03` のみに限定される
- Modbus slave と複数 transport は実装しない
- CRC、frame validation、UART response assembly をこのリポジトリで保守する

## 再評価条件

- function `0x03` 以外が必要になったとき
- RS485 の方向制御を software から行う必要が生じたとき
- `yamodbus` などに AtomVM-compatible transport が追加されたとき
- protocol layer を複数 project から再利用する必要が生じたとき
