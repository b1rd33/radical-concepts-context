#!/bin/bash
# n8n CLI Helper — lets Claude Code interact with local n8n autonomously
# Usage: ./n8n-cli.sh <command> [args]

# Load config from .env (secrets never hardcoded)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  N8N_URL=$(grep N8N_LOCAL_URL "$ENV_FILE" | cut -d= -f2)
  N8N_API_KEY=$(grep N8N_API_KEY "$ENV_FILE" | cut -d= -f2)
else
  N8N_URL="${N8N_LOCAL_URL:-http://localhost:5678}"
  N8N_API_KEY="${N8N_API_KEY:-}"
fi
N8N_URL="${N8N_URL:-http://localhost:5678}"

CURL="curl -s"
HEADERS=(-H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json")

case "$1" in

  # ── List all workflows ──
  list)
    $CURL "$N8N_URL/api/v1/workflows" "${HEADERS[@]}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for w in d.get('data',[]):
    active = '🟢' if w.get('active') else '⚪'
    print(f\"{active} {w['id']} - {w['name']}\")
"
    ;;

  # ── Get workflow details ──
  get)
    $CURL "$N8N_URL/api/v1/workflows/$2" "${HEADERS[@]}" | python3 -c "
import sys,json
wf=json.load(sys.stdin)
print(f\"Name: {wf['name']}\")
print(f\"Active: {wf.get('active', False)}\")
print(f\"Nodes ({len(wf['nodes'])}):\")
for n in wf['nodes']:
    print(f\"  - {n['name']} ({n['type']})\")
"
    ;;

  # ── Get workflow JSON (full) ──
  json)
    $CURL "$N8N_URL/api/v1/workflows/$2" "${HEADERS[@]}"
    ;;

  # ── Update workflow (accepts JSON file path or stdin) ──
  update)
    WF_ID="$2"
    JSON_FILE="$3"
    if [ -n "$JSON_FILE" ]; then
      $CURL -X PUT "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" -d @"$JSON_FILE" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Updated: {d.get('name','FAILED')}\" if 'id' in d else f\"Error: {d}\")
"
    else
      cat | $CURL -X PUT "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" -d @- | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Updated: {d.get('name','FAILED')}\" if 'id' in d else f\"Error: {d}\")
"
    fi
    ;;

  # ── Activate workflow ──
  activate)
    $CURL -X POST "$N8N_URL/api/v1/workflows/$2/activate" "${HEADERS[@]}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Activated: {d.get('name','FAILED')}\" if d.get('active') else f\"Error: {d}\")
"
    ;;

  # ── Deactivate workflow ──
  deactivate)
    $CURL -X POST "$N8N_URL/api/v1/workflows/$2/deactivate" "${HEADERS[@]}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Deactivated: {d.get('name','OK')}\" if not d.get('active') else f\"Error: {d}\")
"
    ;;

  # ── Execute workflow ──
  run)
    $CURL -X POST "$N8N_URL/api/v1/workflows/$2/run" "${HEADERS[@]}" -d '{}' | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Execution started: {d.get('data',{}).get('executionId','?')}\") if 'data' in d else print(f\"Error: {d}\")
"
    ;;

  # ── List executions ──
  executions)
    WF_ID="$2"
    LIMIT="${3:-5}"
    URL="$N8N_URL/api/v1/executions?limit=$LIMIT"
    [ -n "$WF_ID" ] && URL="$URL&workflowId=$WF_ID"
    $CURL "$URL" "${HEADERS[@]}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for e in d.get('data',[]):
    status = '✅' if e.get('status')=='success' else '❌' if e.get('status')=='error' else '⏳'
    print(f\"{status} {e['id'][:8]}... | {e.get('status','?')} | {e.get('startedAt','?')[:19]}\")
"
    ;;

  # ── Create new workflow from JSON file ──
  create)
    JSON_FILE="$2"
    $CURL -X POST "$N8N_URL/api/v1/workflows" "${HEADERS[@]}" -d @"$JSON_FILE" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Created: {d.get('id','?')} - {d.get('name','FAILED')}\") if 'id' in d else print(f\"Error: {d}\")
"
    ;;

  # ── Rename workflow ──
  rename)
    WF_ID="$2"
    NEW_NAME="$3"
    # Get current workflow, change name, push back
    $CURL "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" | python3 -c "
import sys,json
wf=json.load(sys.stdin)
clean={'name':'$NEW_NAME','nodes':wf['nodes'],'connections':wf['connections'],'settings':{'executionOrder':'v1'}}
json.dump(clean,sys.stdout)
" | $CURL -X PUT "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" -d @- | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Renamed: {d.get('name','FAILED')}\") if 'id' in d else print(f\"Error: {d}\")
"
    ;;

  # ── Modify a node parameter ──
  set-node)
    WF_ID="$2"
    NODE_NAME="$3"
    PARAM_PATH="$4"
    NEW_VALUE="$5"
    $CURL "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" | python3 -c "
import sys,json
wf=json.load(sys.stdin)
for node in wf['nodes']:
    if node['name'] == '$NODE_NAME':
        # Navigate param path and set value
        parts = '$PARAM_PATH'.split('.')
        obj = node['parameters']
        for p in parts[:-1]:
            obj = obj[p]
        try:
            obj[parts[-1]] = json.loads('$NEW_VALUE')
        except:
            obj[parts[-1]] = '$NEW_VALUE'
        print(f'Set {node[\"name\"]}.{\".\".join(parts)} = $NEW_VALUE', file=sys.stderr)
clean={'name':wf['name'],'nodes':wf['nodes'],'connections':wf['connections'],'settings':{'executionOrder':'v1'}}
json.dump(clean, sys.stdout)
" | $CURL -X PUT "$N8N_URL/api/v1/workflows/$WF_ID" "${HEADERS[@]}" -d @- | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"Updated: {d.get('name','FAILED')}\") if 'id' in d else print(f\"Error: {d}\")
"
    ;;

  # ── Check n8n status ──
  status)
    $CURL "$N8N_URL/healthz" 2>/dev/null && echo " n8n is running" || echo "❌ n8n is not running"
    ;;

  # ── Help ──
  *)
    echo "n8n CLI Helper"
    echo ""
    echo "Usage: ./n8n-cli.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  status                          Check if n8n is running"
    echo "  list                            List all workflows"
    echo "  get <wf_id>                     Show workflow details"
    echo "  json <wf_id>                    Get full workflow JSON"
    echo "  update <wf_id> <json_file>      Update workflow from JSON"
    echo "  activate <wf_id>                Activate workflow"
    echo "  deactivate <wf_id>              Deactivate workflow"
    echo "  run <wf_id>                     Execute workflow"
    echo "  executions [wf_id] [limit]      List recent executions"
    echo "  create <json_file>              Create workflow from JSON"
    echo "  rename <wf_id> <name>           Rename workflow"
    echo "  set-node <wf_id> <node> <path> <value>  Modify node parameter"
    echo ""
    echo "Workflow IDs:"
    echo "  pW847d2oQEND8j8p  [WF-01] RSS Score & Curate"
    echo "  YDOI8TCY8d3G3aGB  [WF-02] Brett Approval & Script"
    ;;
esac
