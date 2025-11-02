# Setup IAM role and policies for Admin Access Lambda

Write-Host "Creating IAM role for Admin Access Lambda..." -ForegroundColor Cyan

# Create the Lambda execution role
aws iam create-role `
  --role-name AdminAccessLambdaRole `
  --assume-role-policy-document file://iam-trust-policy.json `
  --description "Execution role for Admin Access Management Lambda"

Write-Host "IAM role created: AdminAccessLambdaRole" -ForegroundColor Green

Write-Host "`nAttaching custom policy for DynamoDB and IAM access..." -ForegroundColor Cyan

# Create and attach the custom policy
aws iam put-role-policy `
  --role-name AdminAccessLambdaRole `
  --policy-name AdminAccessPolicy `
  --policy-document file://iam-admin-access-policy.json

Write-Host "Custom policy attached: AdminAccessPolicy" -ForegroundColor Green

Write-Host "`nAttaching AWS managed policy for Lambda basic execution..." -ForegroundColor Cyan

# Attach AWS managed policy for Lambda basic execution
aws iam attach-role-policy `
  --role-name AdminAccessLambdaRole `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

Write-Host "AWS managed policy attached: AWSLambdaBasicExecutionRole" -ForegroundColor Green

Write-Host "`nWaiting for IAM role to propagate..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n✅ IAM setup complete!" -ForegroundColor Green
Write-Host "Role created: AdminAccessLambdaRole" -ForegroundColor White
Write-Host "Policies attached:" -ForegroundColor White
Write-Host "  - AdminAccessPolicy (DynamoDB + IAM management)" -ForegroundColor White
Write-Host "  - AWSLambdaBasicExecutionRole (CloudWatch Logs)" -ForegroundColor White

# Get the role ARN
Write-Host "`nRole ARN:" -ForegroundColor Cyan
aws iam get-role --role-name AdminAccessLambdaRole --query "Role.Arn" --output text
