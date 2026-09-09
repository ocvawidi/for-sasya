SASYA BIRTHDAY - VM DEPLOYMENT

1. Copy this folder to the VM, e.g. /home/ocva/sasya-birthday
2. On the VM, run: python3 server.py
3. Test locally on VM: curl http://127.0.0.1:8000/
4. From Windows host, run Start-SasyaBirthday-Demo.ps1 in PowerShell.
5. The script checks VM 192.168.0.10:8000, then starts cloudflared on the VM via SSH.
6. It prints the generated https://*.trycloudflare.com URL.

The server-side gate returns only a locked page before 2026-09-10 00:00 Asia/Jakarta.
After that time it serves the real index.html.
