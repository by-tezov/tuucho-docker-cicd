- Docker Engine and Docker Compose are required.
- Tested only on Linux.
- Android builder and Android simulator are not supported on macOS.

# Initial Setup
- To build and launch all services for the first time, run:  
  **docker compose --profile all up -d**  
  After the initial startup, replace the profile "all" with "start-auto" to launch only the necessary containers. Jenkins will start other containers on demand.
  **docker compose --profile all down --volumes --rmi all**  

# Access URLs
- Jenkins: http://localhost/jenkins  
- Android simulator VNC: connect to localhost:5900

## Configuration
- Changing the domain, SSL certificate, and key requires advanced setup. Proceed only if you are familiar with these processes.

## Jenkins instance is not supply, you will need to configure you own and keep a backup. Check the readme.

