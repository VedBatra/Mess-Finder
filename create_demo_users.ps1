$url = "https://lbvovrvsczddqaqggltq.supabase.co/auth/v1/signup"
$key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxidm92cnZzY3pkZHFhcWdnbHRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5NTk5OTAsImV4cCI6MjA4ODUzNTk5MH0.ixZp_JNCGPO6xXCUXw2e_0DV7kti6XCH4TVK3n32yXc"

$headers = @{
    "apikey" = $key
    "Authorization" = "Bearer $key"
    "Content-Type" = "application/json"
}

# Create User
$userData = @{
    email = "user@demo.com"
    password = "password123"
    data = @{
        full_name = "Demo User"
        role = "user"
    }
} | ConvertTo-Json

Write-Host "Creating User..."
try {
    $userResponse = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $userData
    Write-Host "User created successfully!"
} catch {
    Write-Host "Error creating user: $_"
}

# Create Owner
$ownerData = @{
    email = "owner@demo.com"
    password = "password123"
    data = @{
        full_name = "Demo Owner"
        role = "owner"
    }
} | ConvertTo-Json

Write-Host "Creating Owner..."
try {
    $ownerResponse = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $ownerData
    Write-Host "Owner created successfully!"
} catch {
    Write-Host "Error creating owner: $_"
}
