# 2026-10-08 ESP32-C5 serial distribution 実機テスト

## 検証環境

- Board A: ESP32-C5 revision 1.0、USB serial `38:44:BE:A5:04:DC`、`/dev/ttyACM0`
- Board B: ESP32-C5 revision 1.0、USB serial `38:44:BE:A5:05:14`、`/dev/ttyACM1`
- UART: `UART1`、115200 baud、TX/RX を交差接続し GND を共有
- Application node: `a@serial.local` と `b@serial.local`

## 発生した問題と判明したこと

1. 最初は ExAtomVM の Mix task を読み込むと `corrupt atom table` が発生した。Application test は Mix task を読み込まないため、この問題を検出できなかった。使用中の OTP 27 toolchain で `mix deps.compile --force` を実行し、依存関係の生成物を再構築すると解決した。
2. Board B は当初 AtomVM `0.7.0-alpha.1` で動作していた。`serial_dist.beam` を読み込めず、`net_kernel` の起動中に crash した。README に記載した `v0.7.0-beta.0` firmware をインストールすると、module が見つからない問題は解決した。現在は両方の board が `0.7.0-beta.0` で動作する。
3. リポジトリの以前の既定値（`UART1`、TX GPIO11、RX GPIO12）では、両方の node が `serial_dist: ready` まで到達したものの handshake が timeout し、node B に `UART read error: ealready` が表示された。起動ログから、GPIO11 と GPIO12 は firmware console の UART pin だと分かった。XIAO ESP32-C5 では D6/TX と D7/RX に相当するため、application UART が firmware の UART0 console と同じ GPIO を使用していた。
4. Project の既定値を UART1 TX は D4/GPIO23、UART1 RX は D5/GPIO24 へ変更した。どちらも XIAO で外部に出ている pin であり、firmware console との競合を避けられる。

XIAO の pinout が誤っているわけではない。D6/GPIO11 と D7/GPIO12 は ESP32-C5 の既定の UART0 TX/RX である。公式 AtomVM firmware が UART0 console 用に使っている GPIO と同じ GPIO へ、別の UART1 peripheral を割り当てたことが競合の原因だった。ESP32-C5 の GPIO routing を使うと、UART1 を動作確認済みの D4/GPIO23 と D5/GPIO24 へ割り当てられる。

## 検証結果

- pin の既定値を変更した後、host で `mix format --check-formatted` と `mix test` を実行し、2 tests、0 failures で完了した。
- 両方の board で flash 書き込みと hash verification に成功した。
- 両方の board が AtomVM `0.7.0-beta.0` で起動することを確認した。
- 以前の D6/D7 配線では、上記のとおり通信に失敗した。
- 2 本の信号線を D4/D5 へ移動すると ping/pong に成功した。両方の node で、TX GPIO23、RX GPIO24 とともに `serial_dist: ready` が表示された。Node B では `demo: sending ping to :a@serial.local` に続いて `demo: received pong from :a@serial.local`、node A では対応する ping の受信と pong の送信が表示された。15 秒間の記録中に crash や UART error は発生しなかった。

## 仕上げ後の再検証

- 不正な build-time configuration を直ちにエラーにする検証を追加し、不正な整数と node alias が flash 前に Mix を停止させることを確認した。
- 5 秒間の pong timeout、ping/pong の動作 test、configuration parser の test を追加した。`mix format --check-formatted` と `mix test` は 9 tests、0 failures で完了した。
- 両方の board を再度 flash し、12 秒間の記録で最終的な ping/pong の動作を確認した。Cookie の値は表示されず、pong 成功後に timeout や想定外 message のログも表示されなかった。
- 最初の検証時から USB device 番号が入れ替わり、serial `38:44:BE:A5:04:DC` は `/dev/ttyACM1`、serial `38:44:BE:A5:05:14` は `/dev/ttyACM0` として認識された。以前の `/dev` 番号を使い続けず、作業のたびに device を識別する必要があることを確認できた。
