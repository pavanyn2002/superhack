# Recreate Admin Access API with proper CORS

Write-Host "Deleting old API Gateway..." -ForegroundColor Yellow
aws apigateway delete-rest-api --rest-api-id jqkpnvtj8f --region us-east-2

Write-Host "`nCreating new API Gateway..." -ForegroundColor Cyan
$apiResponse = aws apigateway create-rest-api --name "AdminAccessAPI" --description "API for Admin Access Management" --region us-east-2 --output json | ConvertFrom-Json
$apiId = $apiResponse.id
Write-Host "API created: $apiId" -ForegroundColor Green

# Get root resource
$rootResponse = aws apigateway get-resources --rest-api-id $apiId --region us-east-2 --output json | ConvertFrom-Json
$rootId = $rootResponse.items[0].id

# Create /provision resource
Write-Host "`nCreating /provision resource..." -ForegroundColor Cyan
$resourceResponse = aws apigateway create-resource --rest-api-id $apiId --parent-id $rootId --path-part "provision" --region us-east-2 --output json | ConvertFrom-Json
$resourceId = $resourceResponse.id

# Enable CORS using AWS CLI
Write-Host "`nEnabling CORS..." -ForegroundColor Cyan
aws apigateway put-method --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --authorization-type NONE --region us-east-2 --no-cli-pager

aws apigateway put-method-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" --region us-east-2 --no-cli-pager

aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --type MOCK --request-templates '{\"application/json\":\"{\\\"statusCode\\\": 200}\"}' --region us-east-2 --no-cli-pager

aws apigateway put-integration-response --rest-api-id $apiId --resource-id $resourceId --http-method OPTIONS --status-code 200 --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' --region us-east-2 --no-cli-pager

# Create POST method
Write-Host "`nCreating POST method..." -ForegroundColor Cyan
aws apigateway put-method --rest-api-id $apiId --resource-id $resourceId --http-method POST --authorization-type NONE --region us-east-2 --no-cli-pager

# Set up Lambda integration
Write-Host "Setting up Lambda integration..." -ForegroundColor Cyan
aws apigateway put-integration --rest-api-id $apiId --resource-id $resourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:063088900393:function:AdminAccessLambda/invocations" --region us-east-2 --no-cli-pager

# Grant permission
Write-Host "`nGranting API Gateway permission..." -ForegroundColor Cyan
aws lambda remove-permission --function-name AdminAccessLambda --statement-id apigateway-access --region us-east-2 2>$null
aws lambda add-permission --function-name AdminAccessLambda --statement-id apigateway-access --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-2:063088900393:$apiId/*/*" --region us-east-2 --no-cli-pager

# Deploy API
Write-Host "`nDeploying API..." -ForegroundColor Cyan
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod --region us-east-2 --no-cli-pager

Write-Host "`n✅ API Gateway recreated successfully!" -ForegroundColor Green
Write-Host "`nNew API Endpoint:" -ForegroundColor Cyan
Write-Host "https://$apiId.execute-api.us-east-2.amazonaws.com/prod/provision" -ForegroundColor White

# Save API ID
$apiId | Out-File -FilePath admin-api-id-new.txt -Encoding utf8
Write-Host "`nAPI ID saved to admin-api-id-new.txt" -ForegroundColor Yellow
Write-Host "Update your dashboards with the new URL!" -ForegroundColor Yellow
