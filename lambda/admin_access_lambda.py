import json
import boto3
import os
import re
import uuid
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name='us-east-2')
iam_client = boto3.client('iam', region_name='us-east-2')

# Environment variables
EMPLOYEES_TABLE = os.environ.get('EMPLOYEES_TABLE', 'Employees')
AUDIT_LOG_TABLE = os.environ.get('AUDIT_LOG_TABLE', 'AuditLog')

# Get table references
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
audit_log_table = dynamodb.Table(AUDIT_LOG_TABLE)

# Custom exceptions
class ValidationError(Exception):
    pass

class ManagerNotFoundError(Exception):
    pass

def validate_input(data):
    """
    Validates input data according to requirements 7.1-7.5
    - Employee IDs: alphanumeric and hyphens only, max 50 chars
    - Employee names: letters, spaces, and hyphens only, max 100 chars
    - All required fields must be present
    """
    # Check required fields
    required_fields = ['manager_employee_id', 'new_employee_id', 'new_employee_name']
    for field in required_fields:
        if field not in data or not data[field]:
            raise ValidationError(f"Missing required field: {field}")
    
    # Validate employee IDs format and length
    employee_id_pattern = re.compile(r'^[A-Za-z0-9-]{1,50}$')
    
    if not employee_id_pattern.match(data['manager_employee_id']):
        raise ValidationError("Manager employee ID must contain only alphanumeric characters and hyphens (max 50 chars)")
    
    if not employee_id_pattern.match(data['new_employee_id']):
        raise ValidationError("New employee ID must contain only alphanumeric characters and hyphens (max 50 chars)")
    
    # Validate employee name format and length
    employee_name_pattern = re.compile(r'^[A-Za-z\s-]{1,100}$')
    
    if not employee_name_pattern.match(data['new_employee_name']):
        raise ValidationError("Employee name must contain only letters, spaces, and hyphens (max 100 chars)")
    
    return True

def verify_manager(manager_employee_id):
    """
    Verifies that the manager exists in the Employees table
    and has an IAM role assigned (requirements 1.1-1.3)
    """
    try:
        # Query DynamoDB for manager record
        response = employees_table.get_item(
            Key={'employee_id': manager_employee_id}
        )
        
        # Check if manager exists
        if 'Item' not in response:
            raise ManagerNotFoundError(f"Manager employee ID '{manager_employee_id}' not found in database")
        
        manager = response['Item']
        
        # Check if manager has IAM role assigned
        if 'iam_role_arn' not in manager or not manager['iam_role_arn']:
            raise ManagerNotFoundError(f"Manager '{manager_employee_id}' has no IAM role assigned")
        
        print(f"Manager verified: {manager['employee_name']} ({manager_employee_id})")
        print(f"Manager IAM role: {manager['iam_role_arn']}")
        
        return manager
        
    except ClientError as e:
        print(f"DynamoDB error during manager verification: {str(e)}")
        raise Exception(f"Database error: {str(e)}")

def get_manager_policies(role_arn):
    """
    Retrieves all IAM policies attached to the manager's role (requirement 2.1)
    Returns list of policy ARNs to be cloned
    """
    try:
        # Extract role name from ARN
        role_name = role_arn.split('/')[-1]
        
        print(f"Retrieving policies for role: {role_name}")
        
        # List all attached policies
        response = iam_client.list_attached_role_policies(RoleName=role_name)
        
        policies = response.get('AttachedPolicies', [])
        policy_arns = [policy['PolicyArn'] for policy in policies]
        
        print(f"Found {len(policy_arns)} policies to clone:")
        for arn in policy_arns:
            print(f"  - {arn}")
        
        if not policy_arns:
            print("Warning: Manager role has no attached policies")
        
        return policy_arns
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchEntity':
            raise Exception(f"IAM role '{role_name}' not found")
        elif error_code == 'AccessDenied':
            raise Exception("Insufficient permissions to list IAM policies")
        else:
            print(f"IAM error retrieving policies: {str(e)}")
            raise Exception(f"Failed to retrieve manager policies: {str(e)}")

def create_iam_role(employee_id, policy_arns):
    """
    Creates a new IAM role for the employee and attaches cloned policies
    (requirements 2.2-2.5, 6.2)
    """
    import time
    
    role_name = f"Employee-{employee_id}-Role"
    
    # Trust policy for the role (allows AWS services to assume the role)
    trust_policy = {
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
    
    try:
        # Create the IAM role with retry logic
        max_retries = 3
        retry_delays = [1, 2, 4]  # Exponential backoff
        
        for attempt in range(max_retries):
            try:
                print(f"Creating IAM role: {role_name} (attempt {attempt + 1}/{max_retries})")
                
                response = iam_client.create_role(
                    RoleName=role_name,
                    AssumeRolePolicyDocument=json.dumps(trust_policy),
                    Description=f"IAM role for employee {employee_id}"
                )
                
                role_arn = response['Role']['Arn']
                print(f"IAM role created: {role_arn}")
                break
                
            except ClientError as e:
                if e.response['Error']['Code'] == 'EntityAlreadyExists':
                    raise Exception(f"IAM role '{role_name}' already exists")
                elif attempt < max_retries - 1:
                    print(f"Retry after {retry_delays[attempt]}s due to: {str(e)}")
                    time.sleep(retry_delays[attempt])
                else:
                    raise
        
        # Attach policies with retry logic
        print(f"Attaching {len(policy_arns)} policies to role...")
        
        for policy_arn in policy_arns:
            for attempt in range(max_retries):
                try:
                    iam_client.attach_role_policy(
                        RoleName=role_name,
                        PolicyArn=policy_arn
                    )
                    print(f"  ✓ Attached policy: {policy_arn}")
                    break
                    
                except ClientError as e:
                    if attempt < max_retries - 1:
                        print(f"  Retry attaching policy after {retry_delays[attempt]}s")
                        time.sleep(retry_delays[attempt])
                    else:
                        print(f"  ✗ Failed to attach policy: {policy_arn}")
                        raise
        
        print(f"Successfully created role with {len(policy_arns)} policies")
        return role_arn
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"IAM error creating role: {error_code} - {str(e)}")
        raise Exception(f"Failed to create IAM role: {str(e)}")

def store_employee_record(employee_data):
    """
    Stores new employee record in DynamoDB (requirements 3.1-3.4)
    """
    import time
    
    try:
        # Check if employee already exists
        response = employees_table.get_item(
            Key={'employee_id': employee_data['employee_id']}
        )
        
        if 'Item' in response:
            raise Exception(f"Employee ID '{employee_data['employee_id']}' already exists in database")
        
        # Prepare employee record
        timestamp = datetime.utcnow().isoformat() + 'Z'
        employee_record = {
            'employee_id': employee_data['employee_id'],
            'employee_name': employee_data['employee_name'],
            'manager_id': employee_data['manager_id'],
            'iam_role_arn': employee_data['iam_role_arn'],
            'iam_role_name': f"Employee-{employee_data['employee_id']}-Role",
            'created_at': timestamp,
            'updated_at': timestamp
        }
        
        # Store with retry logic
        max_retries = 3
        retry_delays = [1, 2, 4]
        
        for attempt in range(max_retries):
            try:
                employees_table.put_item(Item=employee_record)
                print(f"Employee record stored: {employee_data['employee_id']}")
                return employee_record
                
            except ClientError as e:
                if attempt < max_retries - 1:
                    print(f"Retry storing employee after {retry_delays[attempt]}s")
                    time.sleep(retry_delays[attempt])
                else:
                    raise
        
    except ClientError as e:
        print(f"DynamoDB error storing employee: {str(e)}")
        raise Exception(f"Failed to store employee record: {str(e)}")

def log_audit_trail(audit_data):
    """
    Logs access provisioning activity to audit trail (requirements 4.1-4.5)
    """
    try:
        timestamp = datetime.utcnow().isoformat() + 'Z'
        
        audit_record = {
            'request_id': audit_data['request_id'],
            'timestamp': timestamp,
            'manager_employee_id': audit_data.get('manager_id', ''),
            'new_employee_id': audit_data.get('new_employee_id', ''),
            'new_employee_name': audit_data.get('new_employee_name', ''),
            'action': audit_data.get('action', 'PROVISION_ACCESS'),
            'status': audit_data['status']
        }
        
        # Add optional fields
        if 'iam_role_arn' in audit_data:
            audit_record['iam_role_arn'] = audit_data['iam_role_arn']
        
        if 'error_message' in audit_data:
            audit_record['error_message'] = audit_data['error_message']
        
        if 'cloned_policies_count' in audit_data:
            audit_record['cloned_policies_count'] = audit_data['cloned_policies_count']
        
        # Store audit log
        audit_log_table.put_item(Item=audit_record)
        print(f"Audit log created: {audit_data['request_id']} - {audit_data['status']}")
        
    except ClientError as e:
        # Don't fail the main operation if audit logging fails
        print(f"Warning: Failed to log audit trail: {str(e)}")

def rollback_iam_role(role_name):
    """
    Deletes IAM role and detaches policies (requirement 6.1)
    Called when employee record storage fails after IAM role creation
    """
    try:
        print(f"Rolling back IAM role: {role_name}")
        
        # List and detach all policies
        response = iam_client.list_attached_role_policies(RoleName=role_name)
        policies = response.get('AttachedPolicies', [])
        
        for policy in policies:
            iam_client.detach_role_policy(
                RoleName=role_name,
                PolicyArn=policy['PolicyArn']
            )
            print(f"  Detached policy: {policy['PolicyArn']}")
        
        # Delete the role
        iam_client.delete_role(RoleName=role_name)
        print(f"  Deleted role: {role_name}")
        
    except ClientError as e:
        print(f"Warning: Rollback failed for role {role_name}: {str(e)}")

def lambda_handler(event, context):
    """
    Main Lambda handler for Admin Access Management
    """
    request_id = str(uuid.uuid4())
    
    # Set CORS headers
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            data = json.loads(event['body'])
        else:
            data = event.get('body', {})
        
        print(f"Request ID: {request_id}")
        print(f"Processing access request for new employee: {data.get('new_employee_id')}")
        
        # Validate input
        validate_input(data)
        print("✓ Input validation passed")
        
        # Verify manager exists and has IAM role
        manager = verify_manager(data['manager_employee_id'])
        print("✓ Manager verification passed")
        
        # Get manager's IAM policies
        policy_arns = get_manager_policies(manager['iam_role_arn'])
        print(f"✓ Retrieved {len(policy_arns)} policies")
        
        # Create IAM role for new employee
        new_role_arn = create_iam_role(data['new_employee_id'], policy_arns)
        print("✓ IAM role created")
        
        # Store employee record in DynamoDB
        try:
            employee_record = store_employee_record({
                'employee_id': data['new_employee_id'],
                'employee_name': data['new_employee_name'],
                'manager_id': data['manager_employee_id'],
                'iam_role_arn': new_role_arn
            })
            print("✓ Employee record stored")
            
        except Exception as db_error:
            # Rollback IAM role if database storage fails
            print(f"✗ Database storage failed: {str(db_error)}")
            rollback_iam_role(f"Employee-{data['new_employee_id']}-Role")
            raise db_error
        
        # Log successful provisioning to audit trail
        log_audit_trail({
            'request_id': request_id,
            'manager_id': data['manager_employee_id'],
            'new_employee_id': data['new_employee_id'],
            'new_employee_name': data['new_employee_name'],
            'status': 'SUCCESS',
            'iam_role_arn': new_role_arn,
            'cloned_policies_count': len(policy_arns)
        })
        
        # Return success response
        response_body = {
            'success': True,
            'message': 'IAM role provisioned successfully',
            'request_id': request_id,
            'new_employee_id': data['new_employee_id'],
            'new_employee_name': data['new_employee_name'],
            'iam_role_arn': new_role_arn,
            'cloned_policies': policy_arns,
            'created_at': employee_record['created_at']
        }
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(response_body)
        }
        
    except ValidationError as e:
        print(f"✗ Validation error: {str(e)}")
        
        # Log failed attempt
        log_audit_trail({
            'request_id': request_id,
            'manager_id': data.get('manager_employee_id', ''),
            'new_employee_id': data.get('new_employee_id', ''),
            'new_employee_name': data.get('new_employee_name', ''),
            'status': 'FAILED',
            'error_message': str(e)
        })
        
        error_body = {
            'success': False,
            'error': str(e),
            'request_id': request_id
        }
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps(error_body)
        }
    
    except ManagerNotFoundError as e:
        print(f"✗ Manager verification error: {str(e)}")
        
        # Log failed attempt
        log_audit_trail({
            'request_id': request_id,
            'manager_id': data.get('manager_employee_id', ''),
            'new_employee_id': data.get('new_employee_id', ''),
            'new_employee_name': data.get('new_employee_name', ''),
            'status': 'FAILED',
            'error_message': str(e)
        })
        
        error_body = {
            'success': False,
            'error': str(e),
            'request_id': request_id
        }
        return {
            'statusCode': 403,
            'headers': headers,
            'body': json.dumps(error_body)
        }
    
    except Exception as e:
        print(f"✗ Unexpected error: {str(e)}")
        
        # Log failed attempt
        log_audit_trail({
            'request_id': request_id,
            'manager_id': data.get('manager_employee_id', ''),
            'new_employee_id': data.get('new_employee_id', ''),
            'new_employee_name': data.get('new_employee_name', ''),
            'status': 'FAILED',
            'error_message': str(e)
        })
        
        error_body = {
            'success': False,
            'error': 'Internal server error',
            'request_id': request_id
        }
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps(error_body)
        }
