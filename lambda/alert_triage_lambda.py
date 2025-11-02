import json
import boto3
from datetime import datetime
import time
import uuid

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('msp-agent-sessions')

def lambda_handler(event, context):
    """
    Alert Triage Lambda - Analyzes and prioritizes alerts using Claude 3.5
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}'))
        alerts = body.get('alerts', [])
        
        if not alerts:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'No alerts provided'})
            }
        
        # Construct prompt for Claude
        prompt = f"""You are an expert MSP technician analyzing system alerts. Analyze the following alerts and provide a prioritized response.

Alerts to analyze:
{json.dumps(alerts, indent=2)}

Provide your analysis in the following JSON format:
{{
  "total_alerts": <number>,
  "prioritized_alerts": [
    {{
      "alert_id": "<id>",
      "severity": "Critical|High|Medium|Low",
      "priority_score": <1-100>,
      "business_impact": "<description>",
      "recommended_action": "<action>",
      "estimated_resolution_time": "<time>",
      "dependencies": []
    }}
  ],
  "summary": "<overall summary>"
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
        print(f"Bedrock response: {json.dumps(response_body)}")
        
        # Try different response formats
        if 'choices' in response_body:
            ai_response = response_body['choices'][0]['message']['content']
        elif 'output' in response_body:
            ai_response = response_body['output']['text']
        elif 'content' in response_body:
            ai_response = response_body['content'][0]['text']
        else:
            ai_response = str(response_body)
        
        # Strip markdown code blocks if present
        if ai_response.startswith('```json'):
            ai_response = ai_response.replace('```json', '').replace('```', '').strip()
        elif ai_response.startswith('```'):
            ai_response = ai_response.replace('```', '').strip()
        
        # Extract JSON from response
        analysis = json.loads(ai_response)
        
        # Log to DynamoDB
        session_id = str(uuid.uuid4())
        timestamp = int(time.time())
        try:
            table.put_item(
                Item={
                    'session_id': session_id,
                    'timestamp': timestamp,
                    'module': 'alert-triage',
                    'request': json.dumps(alerts),
                    'response': json.dumps(analysis),
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
                'analysis': analysis,
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
