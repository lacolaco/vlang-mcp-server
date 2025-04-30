module main

import os
import json

fn main() {
	msg := 'Hello, V!'
	eprintln(msg)

	// 標準入力からのメッセージを処理する
	for {
		eprintln('Waiting for message...')
		// 入力行を読み取る
		input := os.get_line()
		eprintln('Processing message: ${input}')

		// 空行は終了条件
		if input.trim_space() == '' {
			eprintln('Empty line, ending process')
			break
		}

		output := handle_jsonrpc(input) or {
			// エラーが発生した場合はエラーレスポンスを返す
			eprintln('Error processing request: ${err}')
			continue
		}
		// 処理結果を出力
		println(dump(output))
	}
}

fn handle_jsonrpc(input string) !string {
	rpc := json.decode(JsonRpcRequest, input) or {
		// エラーが発生した場合はエラーレスポンスを返す
		return error('Failed to parse JSON-RPC request: ${err}')
	}
	// メソッドに応じて処理を分岐
	match rpc.method {
		'ping' {
			resp := McpPingResponse{
				jsonrpc: '2.0'
				id:      rpc.id
				result:  struct {}
			}
			return json.encode(resp)
		}
		'initialize' {
			resp := McpInitializeResponse{
				jsonrpc: '2.0'
				id:      rpc.id
				result:  struct {
					protocol_version: '2024-11-05'
					capabilities:     struct {
						tools: struct {
							list_changed: false
						}
					}
					server_info:      struct {
						name:    'ExampleServer'
						version: '1.0.0'
					}
					instructions:     'Initialization successful'
				}
			}
			return json.encode(resp)
		}
		'tools/list' {
			resp := McpToolsListResponse{
				jsonrpc: '2.0'
				id:      rpc.id
				result:  McpToolsListResult{
					tools: [
						Tool{
							name:         'ExampleTool'
							description:  'This is an example tool.'
							input_schema: ToolInputSchema{
								type:       'object'
								properties: {}
								required:   []
							}
						},
					]
				}
			}
			return json.encode(resp)
		}
		else {
			return error('Unsupported method: ${rpc.method}')
		}
	}
}

type MessageId = string | int

struct JsonRpcRequestBase {
	jsonrpc string @[json: 'jsonrpc'; required]
	id      MessageId
	method  string @[required]
}

struct JsonRpcRequest {
	jsonrpc string @[json: 'jsonrpc'; required]
	id      MessageId
	method  string @[required]
	params  string @[raw]
}

struct JsonRpcResponseBase {
	jsonrpc string @[json: 'jsonrpc'; required]
	id      MessageId
}

struct JsonRpcErrorResponse {
	JsonRpcResponseBase
	error struct {
		code    int
		message string
		data    string
	}
}

struct McpInitializeRequest {
	JsonRpcRequestBase
	params struct {
		protocol_version string @[json: 'protocolVersion']
		capabilities     struct {}


		client_info struct {
			name    string
			version string
		} @[json: 'clientInfo']
	} @[required]
}

struct McpInitializeResponse {
	JsonRpcResponseBase
	result struct {
		protocol_version string @[json: 'protocolVersion']
		capabilities     struct {
			tools struct {
				list_changed bool @[json: 'listChanged']
			}
		}
		server_info      struct {
			name    string
			version string
		} @[json: 'serverInfo']
		instructions     string
	}
}

struct McpPingRequest {
	JsonRpcRequestBase
	params struct {}

}

struct McpPingResponse {
	JsonRpcResponseBase
	result struct {}

}

struct McpToolsListRequest {
	JsonRpcRequestBase
	params struct {
		cursor ?string
	}
}

struct McpToolsListResponse {
	JsonRpcResponseBase
	result McpToolsListResult
}

struct McpToolsListResult {
	tools []Tool @[json: 'tools'; required]
}
