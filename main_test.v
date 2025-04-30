module main

import json

fn test_handle_jsonrpc_initialize() {
	// Test message
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

	// Process the message
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpInitializeResponse, resp)!
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert decoded.result.protocol_version == '2024-11-05'
	assert decoded.result.server_info.name == 'ExampleServer'
	assert decoded.result.server_info.version == '1.0.0'
	assert decoded.result.capabilities.tools.list_changed == false
	assert decoded.result.instructions == 'Initialization successful'
}

fn test_handle_jsonrpc_tools_list() {
	// Test message
	message := '
	{
		"jsonrpc": "2.0",
		"id": 1,
		"method": "tools/list",
		"params": {}
	}
'.trim_indent()
	// Process the message
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpToolsListResponse, resp) or { panic('Failed to decode JSON: ${err}') }
	dump(resp)
	dump(decoded)
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert decoded.result.tools.len == 1
	assert decoded.result.tools[0].name == 'echo'
	assert decoded.result.tools[0].description == 'This is an example tool.'
}

fn test_handle_jsonrpc_ping() {
	// Test message
	message := '
	{
		"jsonrpc": "2.0",
		"id": 1,
		"method": "ping",
		"params": {}
	}
'.trim_indent()
	// Process the message
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpPingResponse, resp) or { panic('Failed to decode JSON: ${err}') }
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 1
	assert resp == '{"jsonrpc":"2.0","id":1,"result":{}}'
}

fn test_handle_jsonrpc_tools_call_echo() {
	// Test message
	message := '
	{
		"jsonrpc": "2.0",
		"id": 2,
		"method": "tools/call",
		"params": {
			"name": "echo",
			"arguments": {
				"text": "Hello"
			}
		}
	}
'.trim_indent()
	// Process the message
	resp := handle_jsonrpc(message)!
	decoded := json.decode(McpToolsCallResponse, resp) or { panic('Failed to decode JSON: ${err}') }
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 2
	assert decoded.result.content.len == 1
	assert decoded.result.content[0]['type'] as string == 'text'
	assert decoded.result.content[0]['text'] as string == 'Hello'
	assert decoded.result.is_error == false
}

fn test_json_decode_mcp_tools_call_request() {
	// Test message
	message := '
{
	"jsonrpc": "2.0",
	"id": 2,
	"method": "tools/call",
	"params": {
		"name": "get_weather",
		"arguments": {
			"location": "New York",
			"year": 2023
		}
	}
}
'.trim_indent()
	decoded := json.decode(McpToolsCallRequest, message) or {
		panic('Failed to decode JSON: ${err}')
	}
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 2
	assert decoded.method == 'tools/call'
	assert decoded.params.name == 'get_weather'
	assert decoded.params.arguments['location'] as string == 'New York'
	assert decoded.params.arguments['year'] as f64 == 2023
}

fn test_json_decode_mcp_tools_call_response() {
	// Test message
	message := '
{
	"jsonrpc": "2.0",
	"id": 2,
	"result": {
		"content": [
			{
				"type": "text",
				"text": "Current weather in New York:\nTemperature: 72°F\nConditions: Partly cloudy"
			}
		],
		"isError": false
	}
}
	'.trim_indent()
	decoded := json.decode(McpToolsCallResponse, message) or {
		panic('Failed to decode JSON: ${err}')
	}
	// Verify expected output
	assert decoded.jsonrpc == '2.0'
	assert decoded.id as int == 2
	assert decoded.result.content.len == 1
	c0 := decoded.result.content.clone()[0]
	assert c0['type'] as string == 'text'
	assert c0['text'] as string == 'Current weather in New York:\nTemperature: 72°F\nConditions: Partly cloudy'
	assert decoded.result.is_error == false
}
