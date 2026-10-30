# SETUP GUIDE: do these in order (about 60–90 min)

Assumes Ubuntu (or WSL2 Ubuntu on Windows). Everything in the project is already written.
You only need to plug in your accounts, run the steps, and take 4 screenshots.

---
## Step 0: Make two accounts / tokens (5 min)
1. **GitHub** account → create an **empty public repo** named `calculator-devops` (no README).
2. **Docker Hub** account → create a **public repository** named `calculator`.
   Then Account Settings → Security → **New Access Token** (Read & Write). Copy it.
3. **Gmail App Password**: Google Account → Security → 2-Step Verification (turn on) → App passwords → create one. Copy the 16 characters.

## Step 1: Install tools (10 min)
```bash
sudo apt update
sudo apt install -y openjdk-17-jdk maven git curl docker.io docker-compose-v2

# Jenkins (if the key URL fails, copy the current commands from jenkins.io/doc/book/installing/linux)
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update && sudo apt install -y jenkins

# let Jenkins use Docker, then restart it
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
sudo systemctl restart jenkins
```
Jenkins runs on **http://localhost:8080**. Unlock it with `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
and choose **Install suggested plugins**. Create your admin user.

## Step 2: Fill in your details + create the git history (5 min)
Unzip the project, open a terminal inside `calculator-devops/`:
```bash
./configure.sh <your_dockerhub_username> <your_email>
git config --global user.name  "Santhosh Kiran"
git config --global user.email "<your_email>"
./make-history.sh
git remote add origin https://github.com/<your_github_username>/calculator-devops.git
git push -u origin --all
```
Now on GitHub: you'll see two branches. Open **two Pull Requests** (Compare & pull request):
`feature/calculator-api → main` and `feature/devops-pipeline → main`. **Merge both**. Then locally: `git checkout main && git pull`.

## Step 3: Quick local check (5 min)
```bash
mvn clean test                       # all tests should pass
docker build -t calculator:local .
docker run --rm -p 9090:8080 calculator:local     # 8080 is Jenkins, so use 9090
# another terminal:
curl "http://localhost:9090/api/v1/add?a=2&b=3"
```
Stop it with Ctrl+C.

## Step 4: Jenkins setup (15 min)
**4a. Plugins**: Manage Jenkins → Plugins → Available: make sure **Pipeline, Git, GitHub, Docker Pipeline, Mailer** are installed (suggested plugins cover most).

**4b. Docker Hub credential**: Manage Jenkins → Credentials → System → Global → Add Credentials
- Kind: *Username with password*
- Username: your Docker Hub username, Password: the **access token**
- ID: `dockerhub-creds` ← must be exactly this

**4c. Email**: Manage Jenkins → System
- *System Admin e-mail address*: your Gmail
- Scroll to **E-mail Notification**: SMTP server `smtp.gmail.com`, tick *Use SMTP Authentication*, username = your Gmail, password = the **App Password**, tick *Use SSL*, port `465`.
- Tick *Test configuration by sending test e-mail* → Test. Save.

**4d. Create the job**: New Item → name `calculator-pipeline` → **Pipeline** → OK
- Build Triggers: tick **GitHub hook trigger for GITScm polling**
- Pipeline → Definition: **Pipeline script from SCM** → SCM: Git
- Repository URL: your GitHub repo URL; Branch: `*/main`; Script Path: `Jenkinsfile`
- Save → **Build Now** (first run is manual; it registers the triggers in the Jenkinsfile).

It should go all green: Checkout → Build → Test → Docker Build → Push → Deploy. You get an email.

## Step 5: Auto-trigger from GitHub
The Jenkinsfile already has `pollSCM` (checks GitHub every ~2 min), so auto-trigger works with no extra setup.
For the **instant webhook** (nicer for the demo):
```bash
# install ngrok (ngrok.com/download), then:
ngrok http 8080
```
Copy the `https://xxxx.ngrok-free.app` URL → GitHub repo → Settings → Webhooks → Add webhook
- Payload URL: `https://xxxx.ngrok-free.app/github-webhook/`  (keep the trailing slash)
- Content type: `application/json` → Add webhook.

## Step 6: Verify the deployment
```bash
docker ps
curl "http://localhost:8081/api/v1/add?a=2&b=3"
curl "http://localhost:8081/api/v1/divide?a=5&b=0"
curl  http://localhost:8081/actuator/health
```

## Step 7: Screenshots (deliverable 4)
1. Jenkins **Stage View** all green (job page) + Console Output ending in `Finished: SUCCESS`
2. The **email** notification in your inbox
3. `docker ps` output (calculator + nginx containers, status `healthy`)
4. API responses: add, divide-by-zero (400), health. Terminal curl output or browser is fine.
Bonus: Docker Hub page showing the tags, GitHub PRs page.

## Step 8: Report (deliverable 3)
`Report_SPE_MiniProject.pdf` is included: add your GitHub/Docker Hub links where marked, and edit the "Challenges" section to match what *you* actually hit.

## Step 9: Live demo script (Class 17)
1. Show the green pipeline and `docker ps`.
2. Make a small change (e.g. add a line to `README.md`, or change a message in the code and its test), then:
   `git add -A && git commit -m "Demo change" && git push`
3. Show Jenkins auto-starting, going green, new build number tag in `docker ps` / Docker Hub, and the email.

## If something breaks
| Problem | Fix |
|---|---|
| `permission denied ... docker.sock` in Jenkins | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |
| `mvn: command not found` in Jenkins | `sudo apt install maven`, restart Jenkins |
| Push stage: `unauthorized` | Credential ID must be `dockerhub-creds`; use an access token |
| Port 8081 in use | Change `8081:80` in docker-compose.yml **and** the curl URL in the Jenkinsfile |
| Webhook shows red in GitHub | ngrok URL changed after restart; update it. Polling still works meanwhile |
| Email not sent | Use App Password, SSL, port 465, and set System Admin e-mail to the same Gmail |

## Explain-it cheat sheet (they will ask)
- **Multi-stage Dockerfile**: stage 1 has Maven+JDK to build the JAR; stage 2 is a tiny JRE image with only the JAR → smaller, safer.
- **Layer caching**: `pom.xml` is copied and dependencies downloaded *before* the source, so code changes don't re-download dependencies.
- **Non-root user**: container runs as `app`, not root, to limit damage if compromised.
- **Image tag = build number**: every build is traceable and rollback-able; `latest` also pushed.
- **Credentials store**: Docker Hub token lives in Jenkins, referenced by ID; never in git.
- **Idempotent deploy**: fixed Compose project name (`-p calculator`) → re-run updates in place; unchanged containers aren't recreated.
- **Healthcheck**: Compose runs `wget /actuator/health`; nginx starts only after the app is `healthy` (`depends_on: service_healthy`).
- **Nginx**: reverse proxy on 8081 → calculator:8080 over the private `calc-net` network (the app port isn't published directly).
- **Trigger**: GitHub webhook → Jenkins (`githubPush()`); `pollSCM` is the fallback.
