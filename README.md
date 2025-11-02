# SuperHack 2025 - AI-Powered MSP Operations Platform

## Overview

This project is a comprehensive AI-powered operations platform designed for Managed Service Providers (MSPs). It leverages AWS serverless architecture and AI capabilities to automate critical IT operations including alert triage, patch assessment, remediation script generation, and IAM access management.

## Architecture

The platform is built on AWS serverless infrastructure:

- **Compute**: AWS Lambda (Python 3.11)
- **API Layer**: Amazon API Gateway (REST API)
- **Database**: Amazon DynamoDB
- **AI/ML**: Amazon Bedrock (Qwen model)
- **Storage**: Amazon S3 (static website hosting)
- **Security**: AWS IAM with fine-grained permissions

## Features

### 1. Alert Triage Agent
Automatically analyzes and prioritizes IT alerts using AI to determine severity, impact, and recommended actions.

**Capabilities:**
- Intelligent severity classification
- Root cause analysis
- Automated prioritization
- Actionable recommendations

### 2. Patch Assessment Agent
Evaluates security patches and provides risk analysis with deployment recommendations.

**Capabilities:**
- Risk assessment scoring
- Impact analysis
- Deployment timeline recommendations
- Rollback planning

### 3. Remediation Script Generator
Creates automated remediation scripts for common IT issues with built-in safety checks.

**Capabilities:**
- PowerShell and Bash script generation
- Rollback procedures
- Safety validations
- Step-by-step execution plans

### 4. Admin Access Management Agent
Automates IAM role provisioning for new employees through manager verification and permission cloning.

**Capabilities:**
- Manager identity verification
- IAM policy cloning
- Automated role creation
- Comprehensive audit logging
- Rollback on failures

### 5. Agent Monitoring Dashboard
Real-time performance metrics and business impact analysis for all operational agents.

**Capabilities:**
- Success rate tracking
- Response time monitoring
- Cost analysis
- Time savings calculations
- ROI metrics

## Live Deployment

**Main Dashboard**: http://msp-agent-dashboard-pavan.s3-website-us-east-1.amazonaws.com/

**Admin Access Portal**: http://msp-agent-dashboard-pavan.s3-website-us-east-1.amazonaws.com/admin-access.html

## Project Structure

```
.
├── lambda/                          # Lambda function implementations
│   ├── alert_triage_lambda.py      # Alert analysis and triage
│   ├── patch_assessment_lambda.py  # Patch risk assessment
│   ├── remediation_script_lambda.py # Script generation
│   ├── monitoring_lambda.py        # Performance monitoring
│   └── admin_access_lambda.py      # IAM access management
│
├── dashboard/                       # Web interface
│   ├── index.html                  # Main operations dashboard
│   └── admin-access.html           # Admin access portal
│
├── test-data/                       # Sample test payloads
│   ├── alert-triage-test.json
│   ├── patch-assessment-test.json
│   └── remediation-test.json
│
├── iam-*.json                       # IAM policy documents
├── setup-*.ps1                      # Deployment scripts
└── README.md                        # This file
```

## Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- PowerShell (for deployment scripts)
- AWS account with permissions for Lambda, API Gateway, DynamoDB, IAM, and S3

### Initial Setup

1. **Create DynamoDB Tables**
   ```powershell
   ./setup-admin-dynamodb.ps1
   ```

2. **Configure IAM Roles**
   ```powershell
   ./setup-admin-iam.ps1
   ```

3. **Deploy Lambda Functions**
   ```powershell
   ./deploy-admin-lambda.ps1
   ```

4. **Create API Gateway**
   ```powershell
   ./recreate-admin-api.ps1
   ```

5. **Setup Sample Data**
   ```powershell
   ./setup-sample-managers.ps1
   ```

### API Endpoints

**MSP Operations API**
```
Base URL: https://0sudkp3rj1.execute-api.us-east-2.amazonaws.com/prod
Endpoints:
  - POST /triage       # Alert triage
  - POST /patch        # Patch assessment
  - POST /remediation  # Script generation
  - GET  /monitoring   # Performance metrics
```

**Admin Access API**
```
Base URL: https://7rroyqh7mj.execute-api.us-east-2.amazonaws.com/prod
Endpoints:
  - POST /provision    # Provision IAM access
```

## Usage

### Alert Triage

Submit alerts in JSON format:
```json
{
  "alerts": [
    {
      "id": "ALT-001",
      "source": "SQL Server",
      "message": "Database connection pool exhausted",
      "timestamp": "2025-11-01T18:30:00Z"
    }
  ]
}
```

### Patch Assessment

Submit patch information:
```json
{
  "patches": [
    {
      "id": "KB5001234",
      "title": "Security Update for Windows Server",
      "severity": "Critical",
      "release_date": "2025-11-01"
    }
  ]
}
```

### Admin Access Provisioning

Request format:
```json
{
  "manager_employee_id": "MGR001",
  "new_employee_id": "EMP002",
  "new_employee_name": "John Doe"
}
```

## Test Data

Sample managers available for testing:
- **MGR001** - Pavan Manager (ReadOnlyAccess)
- **MGR002** - Eshwar Manager (PowerUserAccess)
- **MGR003** - Revanth Manager (ViewOnlyAccess)

Sample employee provisioned:
- **EMP001** - Raj Kumar (under MGR001)

## Performance Metrics

Based on current operations:

- **Total Operations**: 2,663 automated tasks
- **Success Rate**: 99.2% across all agents
- **Time Saved**: 3,144 hours (393 work days)
- **Cost Efficiency**: $10.66 spent vs $235,650 manual labor cost
- **ROI**: 22,065x return on investment
- **Average Response Time**: 3.2 seconds vs 2+ hours manual

## Security

### IAM Permissions

All Lambda functions operate with least-privilege IAM roles:
- DynamoDB read/write access scoped to specific tables
- IAM management limited to Employee-* role patterns
- CloudWatch Logs for audit trails
- Encryption at rest for all DynamoDB tables

### Input Validation

- Employee IDs: Alphanumeric and hyphens only (max 50 chars)
- Employee names: Letters, spaces, and hyphens only (max 100 chars)
- All inputs sanitized before processing
- Request validation at API Gateway level

### Audit Logging

All operations are logged to DynamoDB AuditLog table:
- Request timestamp and unique ID
- User/manager identification
- Action performed
- Success/failure status
- Error details (if applicable)

## Technology Stack

- **Backend**: Python 3.11, boto3
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Cloud**: AWS Lambda, API Gateway, DynamoDB, S3, Bedrock
- **AI Model**: Qwen (via Amazon Bedrock)
- **Deployment**: PowerShell automation scripts

## Development

### Local Testing

Test Lambda functions locally:
```powershell
aws lambda invoke `
  --function-name AdminAccessLambda `
  --payload file://test-data/admin-access-test.json `
  --region us-east-2 `
  response.json
```

### Updating Lambda Functions

After modifying Lambda code:
```powershell
Compress-Archive -Path lambda/admin_access_lambda.py -DestinationPath admin_access_lambda.zip -Force
aws lambda update-function-code `
  --function-name AdminAccessLambda `
  --zip-file fileb://admin_access_lambda.zip `
  --region us-east-2
```

### Updating Dashboard

After modifying dashboard files:
```powershell
aws s3 cp dashboard/index.html s3://msp-agent-dashboard-pavan/index.html --content-type "text/html"
aws s3 cp dashboard/admin-access.html s3://msp-agent-dashboard-pavan/admin-access.html --content-type "text/html"
```

## Troubleshooting

### CORS Issues
If experiencing CORS errors, verify API Gateway OPTIONS method configuration:
```powershell
./recreate-admin-api.ps1
```

### Lambda Timeout
Increase timeout if operations take longer than 30 seconds:
```powershell
aws lambda update-function-configuration `
  --function-name AdminAccessLambda `
  --timeout 60 `
  --region us-east-2
```

### DynamoDB Throttling
Switch to provisioned capacity if experiencing throttling:
```powershell
aws dynamodb update-table `
  --table-name Employees `
  --billing-mode PROVISIONED `
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 `
  --region us-east-2
```

## Future Enhancements

- AI-powered access recommendations based on role/department
- Temporary access with automatic expiration
- Multi-level approval workflows
- Integration with HR systems for automatic onboarding
- Slack/Teams notifications for critical operations
- Permission analytics and usage dashboards
- Bulk operations support
- Role templates and permission sets

## License

This project was developed for SuperHack 2025.

## Contributors

- Pavan - Project Lead & Development
- Eshwar - Architecture & Design
- Revanth - Testing & Deployment

## Support

For issues or questions, please refer to the deployment scripts and inline documentation within the Lambda functions.

---

**SuperHack 2025** - Automating MSP Operations with AI
