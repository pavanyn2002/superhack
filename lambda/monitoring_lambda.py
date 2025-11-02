import json
import boto3
from boto3.dynamodb.conditions import Key
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('msp-agent-sessions')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    Monitoring Lambda - Returns metrics and session data from DynamoDB
    """
    try:
        # Scan all sessions (limit to last 100 for performance)
        response = table.scan(Limit=100)
        items = response.get('Items', [])
        
        # Calculate metrics
        total_sessions = len(items)
        success_count = sum(1 for item in items if item.get('status') == 'success')
        error_count = sum(1 for item in items if item.get('status') == 'error')
        
        # Group by module
        module_stats = {}
        for item in items:
            module = item.get('module', 'unknown')
            if module not in module_stats:
                module_stats[module] = {
                    'total': 0,
                    'success': 0,
                    'error': 0,
                    'avg_processing_time': 0,
                    'total_processing_time': 0
                }
            
            module_stats[module]['total'] += 1
            if item.get('status') == 'success':
                module_stats[module]['success'] += 1
            else:
                module_stats[module]['error'] += 1
            
            processing_time = int(item.get('processing_time', 0))
            module_stats[module]['total_processing_time'] += processing_time
        
        # Calculate averages
        for module in module_stats:
            if module_stats[module]['total'] > 0:
                module_stats[module]['avg_processing_time'] = round(
                    module_stats[module]['total_processing_time'] / module_stats[module]['total']
                )
        
        # Get recent sessions (last 10)
        recent_sessions = sorted(items, key=lambda x: int(x.get('timestamp', 0)), reverse=True)[:10]
        
        # Format recent sessions
        formatted_sessions = []
        for session in recent_sessions:
            formatted_sessions.append({
                'session_id': session.get('session_id'),
                'timestamp': int(session.get('timestamp', 0)),
                'module': session.get('module'),
                'status': session.get('status'),
                'processing_time': int(session.get('processing_time', 0))
            })
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'metrics': {
                    'total_sessions': total_sessions,
                    'success_count': success_count,
                    'error_count': error_count,
                    'success_rate': round((success_count / total_sessions * 100) if total_sessions > 0 else 0, 2)
                },
                'module_stats': module_stats,
                'recent_sessions': formatted_sessions
            }, cls=DecimalEncoder)
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
