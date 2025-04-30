
module main

import json

fn test_handle_jsonrpc_initialize() {
	// テスト用のメッセージ
	message := '
	{
		"jsonrpc": "2.0",
		"id": 1,
		"method": "initialize",
		"params": {
			"protocolVersion": "2024-11-05",
			"capabilities": {
				"roots": {
					"listChanged": true
				},
				"sampling": {}
			},
			"clientInfo": {
				"name": "ExampleClient",
				"version": "1.0.0"
			}
		}
	}
'.trim_indent()

	// メッセージを処理
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpInitializeResponse, resp)!
	// 期待される出力を確認
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert decoded.result.protocol_version == '2024-11-05'
	assert decoded.result.server_info.name == 'ExampleServer'
	assert decoded.result.server_info.version == '1.0.0'
	assert decoded.result.capabilities.tools.list_changed == false
	assert decoded.result.instructions == 'Initialization successful'
}

fn test_handle_jsonrpc_tools_list() {
	// テスト用のメッセージ
	message := '
	{
		"jsonrpc": "2.0",
		"id": 1,
		"method": "tools/list",
		"params": {}
	}
'.trim_indent()
	// メッセージを処理
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpToolsListResponse, resp) or { panic('Failed to decode JSON: ${err}') }
	dump(resp)
	dump(decoded)
	// 期待される出力を確認
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert decoded.result.tools.len == 1
	assert decoded.result.tools[0].name == 'ExampleTool'
	assert decoded.result.tools[0].description == 'This is an example tool.'
}

fn test_handle_jsonrpc_ping() {
	// テスト用のメッセージ
	message := '
	{
		"jsonrpc": "2.0",
		"id": 1,
		"method": "ping",
		"params": {}
	}
'.trim_indent()
	// メッセージを処理
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpPingResponse, resp) or { panic('Failed to decode JSON: ${err}') }
	// 期待される出力を確認
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert resp == '{"jsonrpc":"2.0","id":1,"result":{}}'
}
