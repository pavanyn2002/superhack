# Create sample manager data for testing Admin Access Agent

Write-Host "Creating sample IAM roles for managers..." -ForegroundColor Cyan

# Trust policy for manager roles
$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@

$trustPolicy | Out-File -FilePath manager-trust-policy.json -Encoding utf8

# Create Manager 1 - with ReadOnlyAccess
Write-Host "`nCreating Manager-MGR001-Role..." -ForegroundColor Yellow
aws iam create-role `
  --role-name Manager-MGR001-Role `
  --assume-role-policy-document file://manager-trust-policy.json `
  --description "Manager role for MGR001"

aws iam attach-role-policy `
  --role-name Manager-MGR001-Role `
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

$mgr001Arn = aws iam get-role --role-name Manager-MGR001-Role --query "Role.Arn" --output text

# Create Manager 2 - with PowerUserAccess
Write-Host "`nCreating Manager-MGR002-Role..." -ForegroundColor Yellow
aws iam create-role `
  --role-name Manager-MGR002-Role `
  --assume-role-policy-document file://manager-trust-policy.json `
  --description "Manager role for MGR002"

aws iam attach-role-policy `
  --role-name Manager-MGR002-Role `
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

$mgr002Arn = aws iam get-role --role-name Manager-MGR002-Role --query "Role.Arn" --output text

# Create Manager 3 - with ViewOnlyAccess
Write-Host "`nCreating Manager-MGR003-Role..." -ForegroundColor Yellow
aws iam create-role `
  --role-name Manager-MGR003-Role `
  --assume-role-policy-document file://manager-trust-policy.json `
  --description "Manager role for MGR003"

aws iam attach-role-policy `
  --role-name Manager-MGR003-Role `
  --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess

$mgr003Arn = aws iam get-role --role-name Manager-MGR003-Role --query "Role.Arn" --output text

Write-Host "`n✅ Manager IAM roles created!" -ForegroundColor Green

Write-Host "`nAdding manager records to Employees table..." -ForegroundColor Cyan

# Add Manager 1 to DynamoDB
aws dynamodb put-item `
  --table-name Employees `
  --item "{
    \"employee_id\": {\"S\": \"MGR001\"},
    \"employee_name\": {\"S\": \"Alice Manager\"},
    \"manager_id\": {\"S\": \"ADMIN\"},
    \"iam_role_arn\": {\"S\": \"$mgr001Arn\"},
    \"iam_role_name\": {\"S\": \"Manager-MGR001-Role\"},
    \"created_at\": {\"S\": \"2025-11-01T00:00:00Z\"},
    \"updated_at\": {\"S\": \"2025-11-01T00:00:00Z\"}
  }" `
  --region us-east-2

Write-Host "  ✓ Added MGR001 - Alice Manager (ReadOnlyAccess)" -ForegroundColor White

# Add Manager 2 to DynamoDB
aws dynamodb put-item `
  --table-name Employees `
  --item "{
    \"employee_id\": {\"S\": \"MGR002\"},
    \"employee_name\": {\"S\": \"Bob Manager\"},
    \"manager_id\": {\"S\": \"ADMIN\"},
    \"iam_role_arn\": {\"S\": \"$mgr002Arn\"},
    \"iam_role_name\": {\"S\": \"Manager-MGR002-Role\"},
    \"created_at\": {\"S\": \"2025-11-01T00:00:00Z\"},
    \"updated_at\": {\"S\": \"2025-11-01T00:00:00Z\"}
  }" `
  --region us-east-2

Write-Host "  ✓ Added MGR002 - Bob Manager (PowerUserAccess)" -ForegroundColor White

# Add Manager 3 to DynamoDB
aws dynamodb put-item `
  --table-name Employees `
  --item "{
    \"employee_id\": {\"S\": \"MGR003\"},
    \"employee_name\": {\"S\": \"Carol Manager\"},
    \"manager_id\": {\"S\": \"ADMIN\"},
    \"iam_role_arn\": {\"S\": \"$mgr003Arn\"},
    \"iam_role_name\": {\"S\": \"Manager-MGR003-Role\"},
    \"created_at\": {\"S\": \"2025-11-01T00:00:00Z\"},
    \"updated_at\": {\"S\": \"2025-11-01T00:00:00Z\"}
  }" `
  --region us-east-2

Write-Host "  ✓ Added MGR003 - Carol Manager (ViewOnlyAccess)" -ForegroundColor White

Write-Host "`n✅ Sample manager data created!" -ForegroundColor Green
Write-Host "`nTest Managers:" -ForegroundColor Cyan
Write-Host "  MGR001 - Alice Manager (ReadOnlyAccess)" -ForegroundColor White
Write-Host "  MGR002 - Bob Manager (PowerUserAccess)" -ForegroundColor White
Write-Host "  MGR003 - Carol Manager (ViewOnlyAccess)" -ForegroundColor White

# Clean up temp file
Remove-Item manager-trust-policy.json -ErrorAction SilentlyContinue
