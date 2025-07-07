# server_monitor

# Simple PHP & Bash Server Performance Monitor

A lightweight and efficient server monitoring tool that uses a Bash script to generate a static HTML performance report, which is then displayed by a simple PHP page.

This approach is highly performant because the PHP script only reads a static file, avoiding the overhead of running multiple system commands on every page load. The report is kept up-to-date by a cron job.

### Features
- **IP Address & Hostname:** Quickly identify the machine.
- **System Uptime:** See how long the server has been running.
- **CPU Usage:** View current CPU utilization and load average.
- **Memory Usage:** See a clear breakdown of total and used memory.
- **Disk Usage:** A clear `df -h` style table for all main partitions.
- **Top Processes:** Lists the top 5 processes by CPU and Memory usage.
- **Efficient & Secure:** No direct `shell_exec` from PHP. The report generation is separate from the display logic.

### Screenshot


### Setup Instructions

#### 1. Clone the Repository
Clone this repository to a location on your server, for example, in `/opt/`.

```bash
git clone https://github.com/your-username/server-performance-monitor.git
cd server-performance-monitor
```

#### 2. Configure Your Web Server
Point your web server's document root to the `public_html` directory inside the cloned repository.

**Apache Example (`/etc/apache2/sites-available/performance.conf`):**
```apacheconf
<VirtualHost *:80>
    ServerName your-domain.com
    DocumentRoot /path/to/server-performance-monitor/public_html
    <Directory /path/to/server-performance-monitor/public_html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

**Nginx Example (`/etc/nginx/sites-available/performance`):**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/server-performance-monitor/public_html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock; # Adjust PHP version
    }
}
```
Remember to enable the site and restart your web server.

#### 3. Set Permissions
The script needs to be executable, and the `report` directory needs to be writable by the user who will run the cron job (e.g., `www-data` or your own user).

```bash
# Make the script executable
chmod +x generate_report.sh

# The script will create the report/ directory, but let's set permissions on the parent
# If your cron job runs as www-data:
sudo chown -R www-data:www-data /path/to/server-performance-monitor/public_html
# Or if it runs as you:
sudo chown -R $USER:$USER /path/to/server-performance-monitor/public_html
```

#### 4. Install Dependencies
Ensure you have the necessary command-line tools installed.
```bash
# For Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y coreutils curl gawk procps sysstat

# For RHEL/CentOS/Fedora
sudo yum install -y coreutils curl gawk procps-ng sysstat
```

#### 5. Set Up the Cron Job
Set up a cron job to run the `generate_report.sh` script periodically. To run it every 5 minutes:

1.  Open the crontab editor: `crontab -e`
2.  Add the following line, **using the absolute path** to your script:

```crontab
*/5 * * * * /path/to/server-performance-monitor/generate_report.sh > /dev/null 2>&1
```

#### 6. Run Manually Once
Run the script once to generate the initial report and check for errors.
```bash
./generate_report.sh
```
Now, visit your configured domain or server IP to see the report.
