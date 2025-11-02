# Deploy Admin Access Lambda function

Write-Host "Packaging Lambda function..." -ForegroundColor Cyan

# Create deployment package
Compress-Archive -Path lambda/admin_access_lambda.py -DestinationPath admin_access_lambda.zip -Force

Write-Host "Lambda package created: admin_access_lambda.zip" -ForegroundColor Green

Write-Host "`nDeploying Lambda function..." -ForegroundColor Cyan

# Deploy Lambda function
aws lambda create-function `
  --function-name AdminAccessLambda `
  --runtime python3.11 `
  --role arn:aws:iam::063088900393:role/AdminAccessLambdaRole `
  --handler admin_access_lambda.lambda_handler `
  --zip-file fileb://admin_access_lambda.zip `
  --timeout 30 `
  --memory-size 256 `
  --environment "Variables={EMPLOYEES_TABLE=Employees,AUDIT_LOG_TABLE=AuditLog}" `
  --region us-east-2

Write-Host "`n✅ Lambda function deployed!" -ForegroundColor Green
Write-Host "Function name: AdminAccessLambda" -ForegroundColor White
Write-Host "Runtime: Python 3.11" -ForegroundColor White
Write-Host "Timeout: 30 seconds" -ForegroundColor White
Write-Host "Memory: 256 MB" -ForegroundColor White

# Get function ARN
Write-Host "`nFunction ARN:" -ForegroundColor Cyan
aws lambda get-function --function-name AdminAccessLambda --region us-east-2 --query "Configuration.FunctionArn" --output text
