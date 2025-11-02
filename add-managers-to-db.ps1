# Add manager records to DynamoDB

Write-Host "Adding manager records to Employees table..." -ForegroundColor Cyan

# Manager 1
aws dynamodb put-item --table-name Employees --region us-east-2 --item '{\"employee_id\":{\"S\":\"MGR001\"},\"employee_name\":{\"S\":\"Alice Manager\"},\"manager_id\":{\"S\":\"ADMIN\"},\"iam_role_arn\":{\"S\":\"arn:aws:iam::063088900393:role/Manager-MGR001-Role\"},\"iam_role_name\":{\"S\":\"Manager-MGR001-Role\"},\"created_at\":{\"S\":\"2025-11-01T00:00:00Z\"},\"updated_at\":{\"S\":\"2025-11-01T00:00:00Z\"}}'

Write-Host "  ✓ Added MGR001 - Alice Manager" -ForegroundColor Green

# Manager 2
aws dynamodb put-item --table-name Employees --region us-east-2 --item '{\"employee_id\":{\"S\":\"MGR002\"},\"employee_name\":{\"S\":\"Bob Manager\"},\"manager_id\":{\"S\":\"ADMIN\"},\"iam_role_arn\":{\"S\":\"arn:aws:iam::063088900393:role/Manager-MGR002-Role\"},\"iam_role_name\":{\"S\":\"Manager-MGR002-Role\"},\"created_at\":{\"S\":\"2025-11-01T00:00:00Z\"},\"updated_at\":{\"S\":\"2025-11-01T00:00:00Z\"}}'

Write-Host "  ✓ Added MGR002 - Bob Manager" -ForegroundColor Green

# Manager 3
aws dynamodb put-item --table-name Employees --region us-east-2 --item '{\"employee_id\":{\"S\":\"MGR003\"},\"employee_name\":{\"S\":\"Carol Manager\"},\"manager_id\":{\"S\":\"ADMIN\"},\"iam_role_arn\":{\"S\":\"arn:aws:iam::063088900393:role/Manager-MGR003-Role\"},\"iam_role_name\":{\"S\":\"Manager-MGR003-Role\"},\"created_at\":{\"S\":\"2025-11-01T00:00:00Z\"},\"updated_at\":{\"S\":\"2025-11-01T00:00:00Z\"}}'

Write-Host "  ✓ Added MGR003 - Carol Manager" -ForegroundColor Green

Write-Host "`n✅ All managers added to database!" -ForegroundColor Green
