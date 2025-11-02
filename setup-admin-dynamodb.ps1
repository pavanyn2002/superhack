# Setup DynamoDB tables for Admin Access Agent

Write-Host "Creating Employees table..." -ForegroundColor Cyan

aws dynamodb create-table `
  --table-name Employees `
  --attribute-definitions AttributeName=employee_id,AttributeType=S AttributeName=manager_id,AttributeType=S `
  --key-schema AttributeName=employee_id,KeyType=HASH `
  --global-secondary-indexes "IndexName=manager_id-index,KeySchema=[{AttributeName=manager_id,KeyType=HASH}],Projection={ProjectionType=ALL}" `
  --billing-mode PAY_PER_REQUEST `
  --sse-specification Enabled=true `
  --region us-east-2

Write-Host "Employees table creation initiated..." -ForegroundColor Green

Write-Host "`nCreating AuditLog table..." -ForegroundColor Cyan

aws dynamodb create-table `
  --table-name AuditLog `
  --attribute-definitions AttributeName=request_id,AttributeType=S AttributeName=timestamp,AttributeType=S `
  --key-schema AttributeName=request_id,KeyType=HASH AttributeName=timestamp,KeyType=RANGE `
  --billing-mode PAY_PER_REQUEST `
  --sse-specification Enabled=true `
  --region us-east-2

Write-Host "AuditLog table creation initiated..." -ForegroundColor Green

Write-Host "`nWaiting for tables to become active..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`nChecking Employees table status..." -ForegroundColor Cyan
aws dynamodb describe-table --table-name Employees --region us-east-2 --query "Table.TableStatus"

Write-Host "`nChecking AuditLog table status..." -ForegroundColor Cyan
aws dynamodb describe-table --table-name AuditLog --region us-east-2 --query "Table.TableStatus"

Write-Host "`n✅ DynamoDB tables setup complete!" -ForegroundColor Green
Write-Host "Tables created:" -ForegroundColor White
Write-Host "  - Employees (with manager_id-index GSI)" -ForegroundColor White
Write-Host "  - AuditLog" -ForegroundColor White
