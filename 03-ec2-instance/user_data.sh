#!/bin/bash
# Update system and install Apache
yum update -y
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create initial index.html
cat > /var/www/html/index.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Initial Page</title>
</head>
<body>
    <h1>Apache is installing...</h1>
    <p>The custom index.html will be deployed shortly.</p>
</body>
</html>
EOL

# Set proper permissions
chown apache:apache /var/www/html/index.html
chmod 644 /var/www/html/index.html