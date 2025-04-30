module main

import io
import os

fn main() {
	msg := 'Hello, V!'
	eprintln(msg)

	// 標準入力からのメッセージを処理する
	mut stdin_reader := io.new_buffered_reader(reader: os.stdin())

	for {
		// 入力行を読み取る
		line := stdin_reader.read_line() or {
			eprintln('Error reading stdin: ${err}')
			break
		}

		// 空行は無視
		if line.trim_space() == '' {
			continue
		}

		// メッセージを処理
		process_message(line.trim_space())
	}
}

fn process_message(message string) {
	// メッセージの処理を実装
	eprintln('Processing message: ${message}')
}
