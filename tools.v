module main

struct Tool {
pub:
	name         string @[required]
	description  string
	input_schema ToolInputSchema @[json: 'inputSchema']
}

struct ToolInputSchema {
pub:
	type       string
	properties map[string]ToolInputSchemaProperty
	required   []string
}

struct ToolInputSchemaProperty {
pub:
	type string
}
