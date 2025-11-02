# Test Bedrock Access Script

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   BEDROCK ACCESS TEST                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Testing API endpoint..." -ForegroundColor Yellow
Write-Host "Region: us-east-2" -ForegroundColor White
Write-Host "Endpoint: /triage`n" -ForegroundColor White

$response = curl -s -X POST "https://0sudkp3rj1.execute-api.us-east-2.amazonaws.com/prod/triage" `
    -H "Content-Type: application/json" `
    -d '{"alerts":[{"id":"TEST-001","source":"Test","message":"Test alert","timestamp":"2025-11-01T00:00:00Z"}]}'

Write-Host "Response:" -ForegroundColor Cyan
Write-Host $response -ForegroundColor White

if ($response -like "*Model access is denied*") {
    Write-Host "`n❌ BEDROCK NOT ENABLED" -ForegroundColor Red
    Write-Host "`nAction Required:" -ForegroundColor Yellow
    Write-Host "  1. Open AWS Console" -ForegroundColor White
    Write-Host "  2. Go to Amazon Bedrock" -ForegroundColor White
    Write-Host "  3. Switch region to us-east-2 (Ohio)" -ForegroundColor White
    Write-Host "  4. Click 'Model access' in left sidebar" -ForegroundColor White
    Write-Host "  5. Click 'Manage model access'" -ForegroundColor White
    Write-Host "  6. Check Anthropic Claude models" -ForegroundColor White
    Write-Host "  7. Click 'Request model access'" -ForegroundColor White
    Write-Host "  8. Wait 1-2 minutes`n" -ForegroundColor White
    Write-Host "See ENABLE-BEDROCK-US-EAST-2.md for detailed guide" -ForegroundColor Green
}
elseif ($response -like "*session_id*" -or $response -like "*analysis*") {
    Write-Host "`n✅ SUCCESS! BEDROCK IS WORKING!" -ForegroundColor Green
    Write-Host "`nYour MSP Operations Agent is fully functional!" -ForegroundColor Cyan
    Write-Host "Dashboard: http://msp-agent-dashboard-pavan.s3-website-us-east-1.amazonaws.com" -ForegroundColor White
}
elseif ($response -like "*error*") {
    Write-Host "`n⚠️  API ERROR" -ForegroundColor Yellow
    Write-Host "Check the error message above for details" -ForegroundColor White
}
else {
    Write-Host "`n❓ UNEXPECTED RESPONSE" -ForegroundColor Yellow
    Write-Host "Check the response above" -ForegroundColor White
}

Write-Host "`n════════════════════════════════════════════`n" -ForegroundColor Cyan
