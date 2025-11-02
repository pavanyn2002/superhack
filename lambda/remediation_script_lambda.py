import json
import boto3
import time
import uuid

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('msp-agent-sessions')

def lambda_handler(event, context):
    """
    Remediation Script Lambda - Generates PowerShell/Bash scripts with rollback using Claude 3.5
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}'))
        platform = body.get('platform', 'windows')
        issue_description = body.get('issue_description', '')
        system_context = body.get('system_context', {})
        
        if not issue_description:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'No issue description provided'})
            }
        
        # Determine script type
        script_type = 'PowerShell' if platform.lower() == 'windows' else 'Bash'
        
        # Construct prompt for Claude
        prompt = f"""You are an expert systems administrator. Generate a production-ready {script_type} script to resolve this issue.

Platform: {platform}
Issue: {issue_description}
System Context: {json.dumps(system_context, indent=2)}

Requirements:
1. Include comprehensive error handling
2. Provide a complete rollback script
3. Add validation checks before and after changes
4. Include clear execution instructions
5. List all prerequisites
6. Add safety warnings
7. Estimate execution time

Provide your response in the following JSON format:
{{
  "platform": "{platform}",
  "script_type": "{script_type}",
  "script": "<complete script with comments>",
  "rollback_script": "<complete rollback script>",
  "prerequisites": ["<list>"],
  "execution_instructions": ["<step by step>"],
  "warnings": ["<safety warnings>"],
  "estimated_execution_time": "<time>",
  "validation_steps": ["<how to verify success>"]
}}

Respond ONLY with valid JSON, no additional text."""

        # Call Bedrock with Qwen
        response = bedrock.invoke_model(
            modelId='qwen.qwen3-32b-v1:0',
            body=json.dumps({
                'max_tokens': 2000,
                'temperature': 0.7,
                'top_p': 0.9,
                'messages': [{
                    'role': 'user',
                    'content': prompt
                }]
            })
        )
        
        # Parse response (Qwen format)
        response_body = json.loads(response['body'].read())
        ai_response = response_body['choices'][0]['message']['content']
        
        # Strip markdown code blocks if present
        if ai_response.startswith('```json'):
            ai_response = ai_response.replace('```json', '').replace('```', '').strip()
        elif ai_response.startswith('```'):
            ai_response = ai_response.replace('```', '').strip()
        
        # Extract JSON from response
        remediation = json.loads(ai_response)
        
        # Log to DynamoDB
        session_id = str(uuid.uuid4())
        timestamp = int(time.time())
        try:
            table.put_item(
                Item={
                    'session_id': session_id,
                    'timestamp': timestamp,
                    'module': 'remediation-script',
                    'request': json.dumps({'platform': platform, 'issue': issue_description}),
                    'response': json.dumps(remediation),
                    'processing_time': response_body.get('usage', {}).get('output_tokens', 0),
                    'status': 'success'
                }
            )
        except Exception as db_error:
            print(f"DynamoDB logging error: {str(db_error)}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'session_id': session_id,
                'remediation': remediation,
                'processing_time': response_body.get('usage', {})
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
