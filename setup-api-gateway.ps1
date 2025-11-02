# API Gateway Setup Script
$API_ID = "riwjcf68nb"
$ROOT_ID = "adypg6dnsj"
$REGION = "us-east-1"
$ACCOUNT_ID = "063088900393"

Write-Host "Setting up API Gateway..." -ForegroundColor Green

# Create /triage resource
Write-Host "`nCreating /triage resource..." -ForegroundColor Yellow
$triageResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part triage --region $REGION --output json | ConvertFrom-Json
$TRIAGE_ID = $triageResource.id
Write-Host "Triage resource ID: $TRIAGE_ID"

# Create /patch-assessment resource
Write-Host "`nCreating /patch-assessment resource..." -ForegroundColor Yellow
$patchResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part patch-assessment --region $REGION --output json | ConvertFrom-Json
$PATCH_ID = $patchResource.id
Write-Host "Patch resource ID: $PATCH_ID"

# Create /remediation resource
Write-Host "`nCreating /remediation resource..." -ForegroundColor Yellow
$remediationResource = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part remediation --region $REGION --output json | ConvertFrom-Json
$REMEDIATION_ID = $remediationResource.id
Write-Host "Remediation resource ID: $REMEDIATION_ID"

# Add POST method to /triage
Write-Host "`nAdding POST method to /triage..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method POST --authorization-type NONE --region $REGION --output json | Out-Null

# Integrate with Lambda
$LAMBDA_ARN = "arn:aws:lambda:us-east-2:${ACCOUNT_ID}:function:alert-triage"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION --output json | Out-Null

# Add Lambda permission
aws lambda add-permission --function-name alert-triage --statement-id apigateway-triage --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" --region us-east-2 2>&1 | Out-Null

# Add POST method to /patch-assessment
Write-Host "`nAdding POST method to /patch-assessment..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $PATCH_ID --http-method POST --authorization-type NONE --region $REGION --output json | Out-Null

# Integrate with Lambda
$LAMBDA_ARN = "arn:aws:lambda:us-east-2:${ACCOUNT_ID}:function:patch-assessment"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $PATCH_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION --output json | Out-Null

# Add Lambda permission
aws lambda add-permission --function-name patch-assessment --statement-id apigateway-patch --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" --region us-east-2 2>&1 | Out-Null

# Add POST method to /remediation
Write-Host "`nAdding POST method to /remediation..." -ForegroundColor Yellow
aws apigateway put-method --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method POST --authorization-type NONE --region $REGION --output json | Out-Null

# Integrate with Lambda
$LAMBDA_ARN = "arn:aws:lambda:us-east-2:${ACCOUNT_ID}:function:remediation-script"
aws apigateway put-integration --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" --region $REGION --output json | Out-Null

# Add Lambda permission
aws lambda add-permission --function-name remediation-script --statement-id apigateway-remediation --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" --region us-east-2 2>&1 | Out-Null

# Enable CORS for all resources
Write-Host "`nEnabling CORS..." -ForegroundColor Yellow

# CORS for /triage
aws apigateway put-method --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method OPTIONS --authorization-type NONE --region $REGION --output json | Out-Null
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true" --region $REGION --output json | Out-Null
aws apigateway put-integration --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method OPTIONS --type MOCK --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' --region $REGION --output json | Out-Null
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $TRIAGE_ID --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' --region $REGION --output json | Out-Null

# CORS for /patch-assessment
aws apigateway put-method --rest-api-id $API_ID --resource-id $PATCH_ID --http-method OPTIONS --authorization-type NONE --region $REGION --output json | Out-Null
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $PATCH_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true" --region $REGION --output json | Out-Null
aws apigateway put-integration --rest-api-id $API_ID --resource-id $PATCH_ID --http-method OPTIONS --type MOCK --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' --region $REGION --output json | Out-Null
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $PATCH_ID --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' --region $REGION --output json | Out-Null

# CORS for /remediation
aws apigateway put-method --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method OPTIONS --authorization-type NONE --region $REGION --output json | Out-Null
aws apigateway put-method-response --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true" --region $REGION --output json | Out-Null
aws apigateway put-integration --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method OPTIONS --type MOCK --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' --region $REGION --output json | Out-Null
aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $REMEDIATION_ID --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' --region $REGION --output json | Out-Null

# Deploy API
Write-Host "`nDeploying API to prod stage..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION --output json | Out-Null

Write-Host "`n✅ API Gateway setup complete!" -ForegroundColor Green
Write-Host "`nYour API URL is:" -ForegroundColor Cyan
Write-Host "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod" -ForegroundColor White

Write-Host "`nEndpoints:" -ForegroundColor Cyan
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/triage" -ForegroundColor White
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/patch-assessment" -ForegroundColor White
Write-Host "  POST https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/remediation" -ForegroundColor White
