- Docker Engine and Docker Compose are required.
- Tested only on Linux.
- Android builder and Android simulator are not supported on macOS.
- **GitLab may take approximately 5 minutes to start**; please monitor the container logs for status.

# Initial Setup
- To build and launch all services for the first time, run:  
  **docker compose --profile all up -d**  
  After the initial startup, replace the profile "all" with "start-auto" to launch only the necessary containers. Jenkins will start other containers on demand.
  **docker compose --profile all down --volumes --rmi all**  

# Access URLs
- Jenkins: http://localhost/jenkins  
- GitLab: http://localhost/gitlab  (login: root, password: Baby1MoreTime)
- Android simulator VNC: connect to localhost:5900

# Cloning the Android Demo Project from GitLab
1. Create a user on GitLab and add an SSH key (or use the ssh key setup/gitlab who belongs to gitlab user).  
   *(Ensure your user has access to the project either via group membership or direct assignment.)*  
2. Add the following configuration to your SSH config file (`~/.ssh/config`):

        Host gitlab
            HostName localhost
            Port 2222
            IdentityFile ~/.ssh/"name of your key"
            ServerAliveInterval 60
            ServerAliveCountMax 5
            TCPKeepAlive yes

3. Clone the demo project using.
4.Gitlab: pipeline: open a merge request with ready label and push on demo Android project.
4.Jenkins: pipeline: open a merge request and push on demo Android project (Jenkins is disabled, go in System and put 4 in master executor to reactivate the webhooks listener).

## Configuration
- Changing the domain, SSL certificate, and key requires advanced setup. Proceed only if you are familiar with these processes.

## Faq
- Sometimes the first build/run of docker compose, Gitlab backup are not properly initiated (repository backup stay empty following ssh failing). Down all and remove volume, then re-build all (volumes included) to fix it.
- For the Standalone Android emulator to work, you need to allow docker to connect to host display (check the comment in the compose file). Tested on Ubuntu 22+ Wayland
- After first build, sometimes the first pipeline launch stuck or fail, restart Gitlab container fix the issue (sometimes Nginx)

# Note
 - I’m still learning GitLab, so my opinion might change over time.
 - For now, I feel Jenkins is more powerful because you can customize almost anything without any limitation, but it requires more work to set up and maintain.
 - GitLab is simpler to use, but as soon as you need something specific or non-standard, it often requires hacks or workarounds (so it required also work and maintain)...
 - Jenkins learn curve needs more work but after, it is only love. Gitlab, easier to learn but quickly limited

