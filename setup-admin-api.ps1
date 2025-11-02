# Setup API Gateway for Admin Access Agent

Write-Host "Creating API Gateway..." -ForegroundColor Cyan

# Create REST API
$apiResponse = aws apigateway create-rest-api `
  --name "AdminAccessAPI" `
  --description "API for Admin Access Management Agent" `
  --region us-east-2 `
  --output json | ConvertFrom-Json

$apiId = $apiResponse.id
Write-Host "API created: $apiId" -ForegroundColor Green

# Get root resource ID
$rootResponse = aws apigateway get-resources `
  --rest-api-id $apiId `
  --region us-east-2 `
  --output json | ConvertFrom-Json

$rootId = $rootResponse.items[0].id

# Create /provision resource
Write-Host "`nCreating /provision resource..." -ForegroundColor Cyan
$resourceResponse = aws apigateway create-resource `
  --rest-api-id $apiId `
  --parent-id $rootId `
  --path-part "provision" `
  --region us-east-2 `
  --output json | ConvertFrom-Json

$resourceId = $resourceResponse.id
Write-Host "Resource created: /provision" -ForegroundColor Green

# Create POST method
Write-Host "`nCreating POST method..." -ForegroundColor Cyan
aws apigateway put-method `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --authorization-type NONE `
  --region us-east-2

# Set up Lambda integration
Write-Host "Setting up Lambda integration..." -ForegroundColor Cyan
aws apigateway put-integration `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --type AWS_PROXY `
  --integration-http-method POST `
  --uri "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:063088900393:function:AdminAccessLambda/invocations" `
  --region us-east-2

# Create OPTIONS method for CORS
Write-Host "`nCreating OPTIONS method for CORS..." -ForegroundColor Cyan
aws apigateway put-method `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method OPTIONS `
  --authorization-type NONE `
  --region us-east-2

# Set up OPTIONS integration (mock)
aws apigateway put-integration `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method OPTIONS `
  --type MOCK `
  --request-templates '{"application/json":"{\"statusCode\":200}"}' `
  --region us-east-2

# Set up OPTIONS method response
aws apigateway put-method-response `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method OPTIONS `
  --status-code 200 `
  --response-parameters "method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false" `
  --region us-east-2

# Set up OPTIONS integration response
aws apigateway put-integration-response `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method OPTIONS `
  --status-code 200 `
  --response-parameters '{\"method.response.header.Access-Control-Allow-Headers\":\"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'\",\"method.response.header.Access-Control-Allow-Methods\":\"'"'"'POST,OPTIONS'"'"'\",\"method.response.header.Access-Control-Allow-Origin\":\"'"'"'*'"'"'\"}' `
  --region us-east-2

# Grant API Gateway permission to invoke Lambda
Write-Host "`nGranting API Gateway permission to invoke Lambda..." -ForegroundColor Cyan
aws lambda add-permission `
  --function-name AdminAccessLambda `
  --statement-id apigateway-access `
  --action lambda:InvokeFunction `
  --principal apigateway.amazonaws.com `
  --source-arn "arn:aws:execute-api:us-east-2:063088900393:$apiId/*/*" `
  --region us-east-2

# Deploy API
Write-Host "`nDeploying API to prod stage..." -ForegroundColor Cyan
aws apigateway create-deployment `
  --rest-api-id $apiId `
  --stage-name prod `
  --region us-east-2

Write-Host "`n✅ API Gateway setup complete!" -ForegroundColor Green
Write-Host "`nAPI Endpoint:" -ForegroundColor Cyan
Write-Host "https://$apiId.execute-api.us-east-2.amazonaws.com/prod/provision" -ForegroundColor White

# Save API ID for later use
$apiId | Out-File -FilePath admin-api-id.txt -Encoding utf8
Write-Host "`nAPI ID saved to admin-api-id.txt" -ForegroundColor Yellow
