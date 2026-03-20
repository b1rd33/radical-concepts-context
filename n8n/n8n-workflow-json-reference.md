# n8n Workflow JSON Reference for `POST`/`PUT` to `/api/v1/workflows`

This note is a practical reference for generating n8n workflows programmatically.

It is based on:

- n8n docs for workflow creation and node docs
- official n8n example workflow JSON from `docs.n8n.io/_workflows/...`
- n8n source in `n8n-io/n8n`
- n8n GitHub issues where exported workflow JSON is shown inline

Important version note:

- n8n workflow JSON is not perfectly stable across node `typeVersion`s.
- The safest pattern is: create the node once in the UI on the exact n8n version you run, export the workflow, and then reuse that exported `parameters` block as your template.
- The core workflow envelope, connection model, credential references, and most node types below are stable enough to generate directly.

## 1. API Shape

For current public API usage, the payload for workflow creation/update matches the normal exported workflow structure:

```json
{
  "name": "My workflow",
  "nodes": [],
  "connections": {},
  "settings": {}
}
```

In practice, these are the core fields you should treat as required/safe:

- `name`
- `nodes`
- `connections`
- `settings`

Common extra fields seen in exports or responses:

- `id`
- `active`
- `tags`
- `pinData`
- `versionId`
- `meta`
- `staticData`

Safe rule:

- For `POST /api/v1/workflows`, send the create payload without response-only fields unless you know your instance accepts them.
- For `PUT /api/v1/workflows/{id}`, start from a `GET` of the existing workflow, modify only what you need, then send the updated object back.

## 2. Node Object Shape

Every node in `nodes[]` follows this general structure:

```json
{
  "id": "uuid-or-string",
  "name": "Node Name",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.4,
  "position": [420, 300],
  "parameters": {},
  "credentials": {}
}
```

Common node fields:

- `id`: usually a UUID string in modern exports, but older exports often use numeric strings.
- `name`: must match the keys used in `connections`.
- `type`: node type identifier.
- `typeVersion`: must match the parameter shape you generate.
- `position`: `[x, y]`.
- `parameters`: node-specific config.
- `credentials`: optional, keyed by credential type.
- Optional flags: `disabled`, `alwaysOutputData`, `continueOnFail`, `notes`, `notesInFlow`, `webhookId`.

## 3. Credential References

Credential references are embedded on the node, not in top-level workflow JSON:

```json
{
  "credentials": {
    "supabaseApi": {
      "id": "X99999h356h356h99ayU7",
      "name": "Tabela Teste"
    }
  }
}
```

Pattern:

```json
{
  "<credentialType>": {
    "id": "<credential-id>",
    "name": "<credential-name>"
  }
}
```

Examples verified from sources:

- `supabaseApi`
- `openRouterApi`

## 4. Connections JSON

`connections` is keyed by source node name.

Each source node contains one or more connection types:

- `main`
- `ai_languageModel`
- `ai_outputParser`
- other sub-node connection types depending on the AI node

`main` uses this structure:

```json
{
  "Source Node": {
    "main": [
      [
        {
          "node": "Target Node",
          "type": "main",
          "index": 0
        }
      ]
    ]
  }
}
```

Interpretation:

- Outer array index = output port on the source node.
- Inner array = all destinations wired from that output port.
- `index` = input index on the target node.

## 5. IF Node Branching

For `IF`, output `0` is the `true` branch and output `1` is the `false` branch.

Example connection block:

```json
{
  "If": {
    "main": [
      [
        {
          "node": "True Branch Node",
          "type": "main",
          "index": 0
        }
      ],
      [
        {
          "node": "False Branch Node",
          "type": "main",
          "index": 0
        }
      ]
    ]
  }
}
```

This matches n8n's two-output IF behavior and the exported branch array format.

## 6. AI Sub-node Connections

AI nodes use dedicated connection types instead of `main`.

Verified example for OpenRouter Chat Model -> Basic LLM Chain:

```json
{
  "OpenRouter Chat Model": {
    "ai_languageModel": [
      [
        {
          "node": "Basic LLM Chain",
          "type": "ai_languageModel",
          "index": 0
        }
      ]
    ]
  }
}
```

Meaning:

- The source node is the model node.
- The connection type is `ai_languageModel`.
- The target node is the chain.

## 7. Workflow Envelope Example

Minimal create payload:

```json
{
  "name": "Generated workflow",
  "nodes": [
    {
      "id": "manual-trigger-1",
      "name": "When clicking 'Test workflow'",
      "type": "n8n-nodes-base.manualTrigger",
      "typeVersion": 1,
      "position": [260, 300],
      "parameters": {}
    }
  ],
  "connections": {},
  "settings": {}
}
```

## 8. Node Reference

### 8.1 Schedule Trigger

Current source shows `Schedule Trigger` stores timing rules under `parameters.rule`.

Hourly example:

```json
{
  "id": "schedule-1",
  "name": "Schedule Trigger",
  "type": "n8n-nodes-base.scheduleTrigger",
  "typeVersion": 1.2,
  "position": [260, 300],
  "parameters": {
    "rule": {
      "interval": [
        {
          "field": "hours",
          "hoursInterval": 1,
          "triggerAtMinute": 0
        }
      ]
    }
  }
}
```

Cron example:

```json
{
  "parameters": {
    "rule": {
      "cronExpression": "0 9 * * 1-5"
    }
  }
}
```

Version caveat:

- Older exports may use a different schedule shape.
- Current source clearly uses `rule`-based configuration.

### 8.2 Supabase

Verified from n8n source and exported workflow JSON in issue `#16789`.

Get row(s) example:

```json
{
  "id": "supabase-get-1",
  "name": "Get a row",
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "position": [860, 0],
  "parameters": {
    "operation": "get",
    "tableId": "user",
    "filters": {
      "conditions": [
        {
          "keyName": "user_id",
          "keyValue": "={{ $('Edit Fields').item.json.user_id }}"
        }
      ]
    }
  },
  "alwaysOutputData": true,
  "credentials": {
    "supabaseApi": {
      "id": "credential-id",
      "name": "Supabase account"
    }
  }
}
```

Create row example:

```json
{
  "id": "supabase-create-1",
  "name": "Create row",
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "position": [1280, -140],
  "parameters": {
    "operation": "create",
    "tableId": "user",
    "fieldsUi": {
      "fieldValues": [
        {
          "fieldId": "user_id",
          "fieldValue": "={{ $json.user_id }}"
        },
        {
          "fieldId": "created_at",
          "fieldValue": "now()"
        },
        {
          "fieldId": "user_name",
          "fieldValue": "={{ $json.user_name }}"
        }
      ]
    }
  },
  "credentials": {
    "supabaseApi": {
      "id": "credential-id",
      "name": "Supabase account"
    }
  }
}
```

Important verified Supabase parameter names:

- `operation`
- `tableId`
- `filters.conditions[]`
- `fieldsUi.fieldValues[]`
- `filterType` and `matchType` are used by source for manual filtering in some operations

### 8.3 Code Node (JavaScript)

Verified from n8n source.

```json
{
  "id": "code-1",
  "name": "Code",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [640, 300],
  "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "return items.map(item => ({ json: { ...item.json, processed: true } }));"
  }
}
```

Verified parameter names:

- `mode`: `runOnceForAllItems` or `runOnceForEachItem`
- `language`: `javaScript` or `pythonNative` on v2
- `jsCode`

### 8.4 HTTP Request with Headers

Verified from n8n HTTP Request source.

Typical POST JSON request with headers:

```json
{
  "id": "http-1",
  "name": "HTTP Request",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.4,
  "position": [860, 300],
  "parameters": {
    "method": "POST",
    "url": "https://example.com/api",
    "sendHeaders": true,
    "specifyHeaders": "keypair",
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "=Bearer {{$json.token}}"
        },
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ {\"message\": $json.message, \"userId\": $json.user_id} }}",
    "options": {}
  }
}
```

Verified parameter names from source:

- `method`
- `url`
- `sendHeaders`
- `specifyHeaders`
- `headerParameters.parameters[]`
- `sendBody`
- `specifyBody`
- `jsonBody`

### 8.5 Telegram with Inline Keyboard

Partially verified:

- Source clearly shows `replyMarkup` with value `inlineKeyboard`.
- Recent n8n work on Telegram inline keyboards added a JSON-style way to provide the keyboard.
- The exact serialized field name for the inline keyboard payload is version-sensitive in the sources I could access.

Stable, verified part:

```json
{
  "id": "telegram-1",
  "name": "Telegram",
  "type": "n8n-nodes-base.telegram",
  "typeVersion": 1.2,
  "position": [1080, 300],
  "parameters": {
    "resource": "message",
    "operation": "editMessageText",
    "chatId": "={{ $json.callback_query.message.chat.id }}",
    "messageId": "={{ $json.callback_query.message.message_id }}",
    "text": "Choose an option",
    "replyMarkup": "inlineKeyboard"
  },
  "credentials": {
    "telegramApi": {
      "id": "credential-id",
      "name": "Telegram bot"
    }
  }
}
```

Verified inline keyboard payload shape itself:

```json
[
  [
    {
      "text": "Profile",
      "callback_data": "profile"
    },
    {
      "text": "Settings",
      "callback_data": "settings"
    }
  ],
  [
    {
      "text": "Help",
      "callback_data": "help"
    }
  ]
]
```

Practical rule:

- Use `replyMarkup: "inlineKeyboard"`.
- Generate the keyboard payload as the 2D Telegram button array above.
- Export one Telegram node from your target n8n version once to confirm the exact property key n8n uses to store that array.

### 8.6 Basic LLM Chain

Verified core shape from official docs, official example workflow JSON, and n8n source.

Verified minimal chain:

```json
{
  "id": "chain-1",
  "name": "Basic LLM Chain",
  "type": "@n8n/n8n-nodes-langchain.chainLlm",
  "typeVersion": 1.6,
  "position": [640, 300],
  "parameters": {
    "promptType": "define",
    "text": "Hello"
  }
}
```

System message support is verified by docs under `Chat Messages`, but the exact serialized parameter key for the chat-message collection was not exposed in the official pages I could access.

Practical rule:

- `promptType: "define"` plus `text` is verified.
- System messages are supported.
- Export one UI-created chain with Chat Messages enabled on your exact n8n version and reuse that `parameters` block as your golden template.

### 8.7 OpenRouter Chat Model

Fully verified from exported workflow JSON in issue `#14432`.

```json
{
  "id": "openrouter-1",
  "name": "OpenRouter Chat Model",
  "type": "@n8n/n8n-nodes-langchain.lmChatOpenRouter",
  "typeVersion": 1,
  "position": [840, 520],
  "parameters": {
    "model": "openai/gpt-4o",
    "options": {}
  },
  "credentials": {
    "openRouterApi": {
      "id": "XF6XWQHSvJJgl5Rn",
      "name": "worked"
    }
  }
}
```

### 8.8 IF with Expressions

Fully verified from exported workflow JSON in issue `#16789`.

```json
{
  "id": "if-1",
  "name": "If",
  "type": "n8n-nodes-base.if",
  "typeVersion": 2.2,
  "position": [1080, 0],
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "",
        "typeValidation": "strict",
        "version": 2
      },
      "conditions": [
        {
          "id": "cond-1",
          "leftValue": "={{ $json.user_id }}",
          "rightValue": "",
          "operator": {
            "type": "number",
            "operation": "exists",
            "singleValue": true
          }
        }
      ],
      "combinator": "or"
    },
    "options": {}
  }
}
```

Another verified IF-style condition block from the same source:

```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "strict",
      "version": 2
    },
    "conditions": [
      {
        "id": "cond-a",
        "leftValue": "={{ $json.body.text.message }}",
        "rightValue": "@88888888888",
        "operator": {
          "type": "string",
          "operation": "equals",
          "name": "filter.operator.equals"
        }
      },
      {
        "id": "cond-b",
        "leftValue": "={{ $json.body.isGroup }}",
        "rightValue": "",
        "operator": {
          "type": "boolean",
          "operation": "false",
          "singleValue": true
        }
      }
    ],
    "combinator": "or"
  }
}
```

### 8.9 Split In Batches / Loop Over Items

Version-sensitive:

- n8n docs now label this node as `Loop Over Items (Split in Batches)`.
- Older and many exported workflows still use the node type `n8n-nodes-base.splitInBatches`.

Typical exported shape:

```json
{
  "id": "split-1",
  "name": "Loop Over Items",
  "type": "n8n-nodes-base.splitInBatches",
  "typeVersion": 1,
  "position": [1280, 300],
  "parameters": {
    "batchSize": 10
  }
}
```

Practical rule:

- Treat `batchSize` as the stable core parameter.
- Confirm the exact `typeVersion` and any newer loop/reset options by exporting one UI-created node from your target n8n version.

## 9. End-to-End Example: Chain + OpenRouter + IF Branches

```json
{
  "name": "AI Example",
  "nodes": [
    {
      "id": "manual-1",
      "name": "When clicking 'Test workflow'",
      "type": "n8n-nodes-base.manualTrigger",
      "typeVersion": 1,
      "position": [200, 300],
      "parameters": {}
    },
    {
      "id": "chain-1",
      "name": "Basic LLM Chain",
      "type": "@n8n/n8n-nodes-langchain.chainLlm",
      "typeVersion": 1.6,
      "position": [460, 300],
      "parameters": {
        "promptType": "define",
        "text": "Summarize: {{$json.input}}"
      }
    },
    {
      "id": "openrouter-1",
      "name": "OpenRouter Chat Model",
      "type": "@n8n/n8n-nodes-langchain.lmChatOpenRouter",
      "typeVersion": 1,
      "position": [460, 520],
      "parameters": {
        "model": "openai/gpt-4o",
        "options": {}
      },
      "credentials": {
        "openRouterApi": {
          "id": "credential-id",
          "name": "OpenRouter"
        }
      }
    },
    {
      "id": "if-1",
      "name": "If",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.2,
      "position": [760, 300],
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 2
          },
          "conditions": [
            {
              "id": "cond-1",
              "leftValue": "={{ $json.output }}",
              "rightValue": "approved",
              "operator": {
                "type": "string",
                "operation": "equals",
                "name": "filter.operator.equals"
              }
            }
          ],
          "combinator": "and"
        },
        "options": {}
      }
    },
    {
      "id": "true-1",
      "name": "True Branch Node",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1040, 220],
      "parameters": {
        "mode": "runOnceForAllItems",
        "language": "javaScript",
        "jsCode": "return items;"
      }
    },
    {
      "id": "false-1",
      "name": "False Branch Node",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1040, 380],
      "parameters": {
        "mode": "runOnceForAllItems",
        "language": "javaScript",
        "jsCode": "return items;"
      }
    }
  ],
  "connections": {
    "When clicking 'Test workflow'": {
      "main": [
        [
          {
            "node": "Basic LLM Chain",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "OpenRouter Chat Model": {
      "ai_languageModel": [
        [
          {
            "node": "Basic LLM Chain",
            "type": "ai_languageModel",
            "index": 0
          }
        ]
      ]
    },
    "Basic LLM Chain": {
      "main": [
        [
          {
            "node": "If",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "If": {
      "main": [
        [
          {
            "node": "True Branch Node",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "False Branch Node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {}
}
```

## 10. Practical Generation Rules

If you are generating workflows in code:

1. Generate stable IDs yourself.
2. Keep `name` unique and deterministic because `connections` uses node names, not node IDs.
3. Always set the exact `typeVersion` you designed the `parameters` for.
4. Create credentials first, then inject credential references into node JSON.
5. For AI nodes and Telegram inline keyboards, treat one exported workflow from your exact n8n version as the source of truth for version-sensitive nested fields.
6. For updates, prefer read-modify-write against the existing workflow JSON instead of constructing a full replacement from scratch every time.

## 11. Sources

Official docs:

- n8n API docs: https://docs.n8n.io/api/
- Workflow management docs: https://docs.n8n.io/embed/managing-workflows/
- Basic LLM Chain docs: https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.chainllm/
- Official example workflow JSON: https://docs.n8n.io/_workflows/advanced-ai/examples/agents_vs_chains.json

Official n8n source:

- Schedule Trigger source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/Schedule/ScheduleTrigger.node.ts
- Supabase source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/Supabase/Supabase.node.ts
- Code node source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/Code/Code.node.ts
- HTTP Request source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/HttpRequest/V3/Description.ts
- Telegram source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/Telegram/Telegram.node.ts
- IF source: https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/If/V2/IfV2.node.ts
- Basic LLM Chain source: https://github.com/n8n-io/n8n/blob/master/packages/%40n8n/nodes-langchain/nodes/chains/ChainLLM/ChainLlm.node.ts

Official n8n repo issues containing exported workflow JSON:

- OpenRouter Chat Model + `ai_languageModel` connection: https://github.com/n8n-io/n8n/issues/14432
- IF + Supabase exported JSON examples: https://github.com/n8n-io/n8n/issues/16789

## 12. What I Could Not Fully Verify

These parts were not exposed cleanly enough in the official pages/source views I could access:

- the exact serialized nested property name for Telegram's inline keyboard JSON payload on the newest node versions
- the exact serialized nested property name used by Basic LLM Chain for the Chat Messages collection when adding a system message
- the latest exact exported `typeVersion`/extended options for Loop Over Items beyond the stable `batchSize` core

Those gaps are version-sensitive, not conceptual gaps. The stable solution is to create one such node in your target n8n UI, export once, and then clone that exact `parameters` block programmatically.
