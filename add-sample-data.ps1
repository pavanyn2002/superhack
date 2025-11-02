# Add Sample Data to DynamoDB

Write-Host "Adding sample data to DynamoDB..." -ForegroundColor Yellow

$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

# Sample 1: Alert Triage
aws dynamodb put-item --table-name msp-agent-sessions --region us-east-1 --item '{
  "session_id": {"S": "sample-001"},
  "timestamp": {"N": "'$timestamp'"},
  "module": {"S": "alert-triage"},
  "request": {"S": "{\"alerts\": [{\"id\": \"ALT-001\", \"source\": \"SQL Server\", \"message\": \"High CPU usage\"}]}"},
  "response": {"S": "{\"total_alerts\": 1, \"prioritized_alerts\": [{\"severity\": \"High\", \"priority_score\": 85}]}"},
  "processing_time": {"N": "347"},
  "status": {"S": "success"}
}' 2>&1 | Out-Null

# Sample 2: Patch Assessment
aws dynamodb put-item --table-name msp-agent-sessions --region us-east-1 --item '{
  "session_id": {"S": "sample-002"},
  "timestamp": {"N": "'$($timestamp + 60)'"},
  "module": {"S": "patch-assessment"},
  "request": {"S": "{\"environment\": \"production\", \"patches\": [{\"id\": \"MS-2025-001\"}]}"},
  "response": {"S": "{\"total_patches\": 1, \"deployment_plan\": [{\"risk_level\": \"High\"}]}"},
  "processing_time": {"N": "412"},
  "status": {"S": "success"}
}' 2>&1 | Out-Null

# Sample 3: Remediation
aws dynamodb put-item --table-name msp-agent-sessions --region us-east-1 --item '{
  "session_id": {"S": "sample-003"},
  "timestamp": {"N": "'$($timestamp + 120)'"},
  "module": {"S": "remediation-script"},
  "request": {"S": "{\"platform\": \"windows\", \"issue\": \"IIS crash\"}"},
  "response": {"S": "{\"script_type\": \"PowerShell\", \"script\": \"# Remediation script\"}"},
  "processing_time": {"N": "523"},
  "status": {"S": "success"}
}' 2>&1 | Out-Null

# Sample 4: Error case
aws dynamodb put-item --table-name msp-agent-sessions --region us-east-1 --item '{
  "session_id": {"S": "sample-004"},
  "timestamp": {"N": "'$($timestamp + 180)'"},
  "module": {"S": "alert-triage"},
  "request": {"S": "{\"alerts\": []}"},
  "response": {"S": "{\"error\": \"No alerts provided\"}"},
  "processing_time": {"N": "0"},
  "status": {"S": "error"}
}' 2>&1 | Out-Null

Write-Host "✓ Added 4 sample records" -ForegroundColor Green
Write-Host "✓ Modules: alert-triage, patch-assessment, remediation-script" -ForegroundColor Green
Write-Host "✓ Includes success and error cases" -ForegroundColor Green
