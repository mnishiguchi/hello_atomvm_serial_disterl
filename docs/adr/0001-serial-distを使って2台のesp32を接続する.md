# 0001: serial_dist を使って 2 台の ESP32 を接続する

## 状態

採用

## 背景

AtomVM `release-0.7` は UART 上の distributed Erlang transport として `serial_dist` を提供している。

このリポジトリでは、2 台の ESP32 間で独自の UART protocol を作ることではなく、AtomVM が提供する distribution を小さな ping / pong で確認したい。

## 決定

- AtomVM の `serial_dist` を専用 UART 上で使用する
- node name は `<alias>@serial.local` 形式の longname とする
- alias は書き込み時の compile-time configuration で決める
- 最初の通信は registered process 間の ping / pong とする
- `serial_dist` が使用する UART を通常の application UART と共有しない
- `serial_dist` の UART GPIO を firmware console の UART GPIO と共有しない

## 理由

AtomVM が提供する transport をそのまま使うことで、独自 framing、validation、link management を実装せずに distributed Erlang 自体の動作へ集中できる。

registered process 間の ping / pong は、最小の構成で node 間 message passing を確認できる。

## 影響

- `serial_dist` 用 UART は distribution transport が占有する
- UART peripheral が異なっていても同じ GPIO を firmware console と共有しないよう、board と firmware の両方の pin 設定を確認する必要がある
- 最初の構成は 2 device の point-to-point 接続に限定される
- 2 台へ異なる alias を設定して個別に flash する必要がある
- RS485 や Modbus RTU はこのリポジトリの対象外とする

## 再評価条件

- 3 node 以上の topology が必要になったとき
- UART を application data と共有する必要が生じたとき
- alias の永続化や動的 provisioning が必要になったとき
