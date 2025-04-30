module main

import os
import json

fn main() {
	msg := 'Hello, V!'
	eprintln(msg)

	// Process messages from standard input
	for {
		eprintln('Waiting for message...')
		// Read input line
		input := os.get_line()
		eprintln('Processing message: ${input}')

		// Empty line is the termination condition
		if input.trim_space() == '' {
			eprintln('Empty line, ending process')
			break
		}

		output := handle_jsonrpc(input) or {
			// Return error response if an error occurs
			eprintln('Error processing request: ${err}')
			continue
		}
		// Output the processing result
		println(dump(output))
	}
}

fn handle_jsonrpc(input string) !string {
	rpc := json.decode(JsonRpcRequestBase, input) or {
		// Return error response if an error occurs
		return error('Failed to parse JSON-RPC request: ${err}')
	}
	// Branch processing according to the method
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
				result:  struct {
					tools: [
						Tool{
							name:         'echo'
							description:  'This is an example tool.'
							input_schema: ToolInputSchema{
								type:       'object'
								properties: {
									'text': ToolInputSchemaProperty{
										type: 'string'
									}
								}
								required:   []
							}
						},
					]
				}
			}
			return json.encode(resp)
		}
		'tools/call' {
			// Decode the request parameters
			call := json.decode(McpToolsCallRequest, input) or {
				return error('Failed to parse tools/call request: ${err}')
			}
			match call.params.name {
				'echo' {
					message := call.params.arguments['text'] or { 'default message' } as string
					resp := McpToolsCallResponse{
						jsonrpc: '2.0'
						id:      call.id
						result:  struct {
							content:  [
								{
									'type': JsonValue('text')
									'text': JsonValue(message)
								},
							]
							is_error: false
						}
					}
					return json.encode(resp)
				}
				else {
					return error('Tool not found')
				}
			}
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
	result struct {
		tools []Tool @[json: 'tools'; required]
	}
}

struct McpToolsCallRequest {
	JsonRpcRequestBase
	params struct {
		name      string
		arguments JsonObject
	}
}

struct McpToolsCallResponse {
	JsonRpcResponseBase
	result struct {
		content  []map[string]JsonValue
		is_error bool @[json: 'isError']
	}
}

type JsonValue = string | f64 | bool | []JsonValue | map[string]JsonValue
type JsonObject = map[string]JsonValue
