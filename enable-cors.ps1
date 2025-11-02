$API_ID = "0sudkp3rj1"
$REGION = "us-east-2"

Write-Host "Enabling CORS for all endpoints..." -ForegroundColor Yellow

# Get resource IDs
$resources = aws apigateway get-resources --rest-api-id $API_ID --region $REGION | ConvertFrom-Json

$triageId = ($resources.items | Where-Object { $_.path -eq "/triage" }).id
$patchId = ($resources.items | Where-Object { $_.path -eq "/patch-assessment" }).id
$remediationId = ($resources.items | Where-Object { $_.path -eq "/remediation" }).id

Write-Host "Resource IDs found:" -ForegroundColor Green
Write-Host "  Triage: $triageId"
Write-Host "  Patch: $patchId"
Write-Host "  Remediation: $remediationId"

# Function to enable CORS for a resource
function Enable-CORS {
    param($ResourceId, $ResourceName)
    
    Write-Host "`nEnabling CORS for $ResourceName..." -ForegroundColor Cyan
    
    # Add OPTIONS method
    aws apigateway put-method --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --authorization-type NONE --region $REGION 2>&1 | Out-Null
    
    # Add method response for OPTIONS
    aws apigateway put-method-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region $REGION 2>&1 | Out-Null
    
    # Add integration for OPTIONS (MOCK)
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --type MOCK --request-templates "application/json={`"statusCode`":200}" --region $REGION 2>&1 | Out-Null
    
    # Add integration response for OPTIONS
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $ResourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',method.response.header.Access-Control-Allow-Methods='POST,OPTIONS',method.response.header.Access-Control-Allow-Origin='*'" --region $REGION 2>&1 | Out-Null
    
    Write-Host "  CORS enabled for $ResourceName" -ForegroundColor Green
}

# Enable CORS for all resources
Enable-CORS -ResourceId $triageId -ResourceName "Triage"
Enable-CORS -ResourceId $patchId -ResourceName "Patch Assessment"
Enable-CORS -ResourceId $remediationId -ResourceName "Remediation"

# Redeploy API
Write-Host "`nRedeploying API..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION 2>&1 | Out-Null

Write-Host "`n✅ CORS enabled and API redeployed!" -ForegroundColor Green
Write-Host "`nAPI URL: https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod" -ForegroundColor Cyan
