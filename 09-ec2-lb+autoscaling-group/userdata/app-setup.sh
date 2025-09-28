#!/bin/bash
# Simple Web Application Setup Script

# Update system
yum update -y

# Install web server
yum install -y httpd

# Start and enable httpd
systemctl start httpd
systemctl enable httpd

# Create a simple HTML page with instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Auto Scaling Test App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .info { background: #f9f9f9; padding: 15px; margin: 10px 0; border-radius: 3px; }
        .header { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 Auto Scaling Test Application</h1>
        
        <div class="info">
            <h2>Instance Information</h2>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Private IP:</strong> $PRIVATE_IP</p>
            <p><strong>Project:</strong> ${project_name}</p>
        </div>

        <div class="info">
            <h2>Application Status</h2>
            <p>✅ Web server is running successfully</p>
            <p>🕒 Server Time: $(date)</p>
            <p>🌐 Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
        </div>

        <div class="info">
            <h2>Load Testing</h2>
            <p>This application is configured for auto scaling testing.</p>
            <p>You can generate load to test the auto scaling policies.</p>
            <button onclick="generateLoad()">Generate CPU Load (Test)</button>
            <script>
                function generateLoad() {
                    fetch('/load-test').then(response => {
                        alert('Load test started! Check CloudWatch metrics.');
                    });
                }
            </script>
        </div>

        <div class="info">
            <h2>Health Check</h2>
            <p>Endpoint: <a href="/health">/health</a></p>
            <p>Status: <span style="color: green;">Healthy</span></p>
        </div>
    </div>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << EOF
{
    "status": "healthy",
    "instance_id": "$INSTANCE_ID",
    "timestamp": "$(date -Iseconds)",
    "service": "web-server"
}
EOF

# Create a simple load test endpoint (for testing auto scaling)
cat > /var/www/html/load-test << EOF
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<html><body>"
echo "<h1>Load Test Started</h1>"
echo "<p>Generating CPU load for 60 seconds...</p>"
echo "</body></html>"

# Generate some CPU load in background (for testing auto scaling)
{
    end=\$((SECONDS+60))
    while [ \$SECONDS -lt \$end ]; do
        echo "scale=5000; 4*a(1)" | bc -l -q > /dev/null
    done
} &
EOF

chmod +x /var/www/html/load-test

# Create a simple status page
cat > /var/www/html/status << EOF
{
    "status": "ok",
    "service": "auto-scaling-test-app",
    "version": "1.0",
    "instance_id": "$INSTANCE_ID",
    "az": "$AVAILABILITY_ZONE"
}
EOF

# Set proper permissions
chown -R apache:apache /var/www/html

echo "Application setup completed successfully!"