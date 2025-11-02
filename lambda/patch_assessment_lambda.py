import json
import boto3
import time
import uuid

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('msp-agent-sessions')

def lambda_handler(event, context):
    """
    Patch Assessment Lambda - Evaluates patches and creates deployment plans using Claude 3.5
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}'))
        environment = body.get('environment', 'development')
        patches = body.get('patches', [])
        
        if not patches:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'No patches provided'})
            }
        
        # Construct prompt for Claude
        env_context = "CRITICAL: This is a production environment. Exercise maximum caution." if environment == 'production' else "Standard procedures apply."
        
        prompt = f"""You are an expert patch management specialist. Analyze these patches for a {environment} environment.

{env_context}

Patches to assess:
{json.dumps(patches, indent=2)}

Provide your assessment in the following JSON format:
{{
  "environment": "{environment}",
  "total_patches": <number>,
  "deployment_plan": [
    {{
      "patch_id": "<id>",
      "risk_level": "Critical|High|Medium|Low",
      "deployment_priority": <1-10>,
      "deployment_window": "<recommended time>",
      "prerequisites": ["<list>"],
      "rollback_strategy": "<strategy>",
      "testing_requirements": ["<list>"],
      "estimated_downtime": "<time>"
    }}
  ],
  "dependencies": [
    {{
      "patch_id": "<id>",
      "depends_on": ["<patch_ids>"]
    }}
  ],
  "overall_recommendation": "<summary>"
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
        assessment = json.loads(ai_response)
        
        # Log to DynamoDB
        session_id = str(uuid.uuid4())
        timestamp = int(time.time())
        try:
            table.put_item(
                Item={
                    'session_id': session_id,
                    'timestamp': timestamp,
                    'module': 'patch-assessment',
                    'request': json.dumps({'environment': environment, 'patches': patches}),
                    'response': json.dumps(assessment),
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
                'assessment': assessment,
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
