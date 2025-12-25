# Icecast2 Audio Streaming Setup for Strudel AI

This guide explains how to set up live audio streaming so others can listen to your Strudel sessions online.

## Overview

- **Icecast2**: Open-source streaming media server (no registration required)
- **Stream Format**: Ogg Vorbis or MP3
- **Public Access**: Anyone with the stream URL can listen

## Installation on Debian 13

```bash
sudo apt update
sudo apt install -y icecast2
```

When prompted:
- Choose to configure Icecast2: Yes
- Hostname: your-server-ip or domain
- Source password: (choose a secure password)
- Relay password: (choose a secure password)
- Admin password: (choose a secure password)

## Configuration

Edit `/etc/icecast2/icecast.xml`:

```xml
<icecast>
    <limits>
        <clients>100</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
    </limits>

    <authentication>
        <source-password>YOUR_SOURCE_PASSWORD</source-password>
        <relay-password>YOUR_RELAY_PASSWORD</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>YOUR_ADMIN_PASSWORD</admin-password>
    </authentication>

    <hostname>your-domain.com</hostname>

    <listen-socket>
        <port>8000</port>
    </listen-socket>

    <mount type="normal">
        <mount-name>/live</mount-name>
        <public>1</public>
        <stream-name>Strudel AI Live</stream-name>
        <stream-description>Live coded music from Strudel AI</stream-description>
        <genre>Electronic</genre>
    </mount>

    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel>
    </logging>
</icecast>
```

## Start Icecast

```bash
sudo systemctl enable icecast2
sudo systemctl start icecast2
sudo systemctl status icecast2
```

## Firewall

```bash
sudo ufw allow 8000/tcp
```

## Streaming from the Application

The application captures Web Audio API output and can stream to Icecast using:

1. **MediaRecorder API**: Capture audio from AudioContext
2. **WebSocket to Server**: Send audio chunks to Node.js backend
3. **Node.js to Icecast**: Forward audio to Icecast mount point

### Stream URL for Listeners

```
http://your-server:8000/live
```

### Embed in HTML

```html
<audio controls autoplay>
    <source src="http://your-server:8000/live" type="audio/ogg">
    Your browser does not support the audio element.
</audio>
```

## Admin Interface

Access Icecast admin at: `http://your-server:8000/admin/`

## Alternative: SHOUTcast

If you prefer SHOUTcast (also open-source for v1):

```bash
# Download SHOUTcast DNAS
wget http://download.nullsoft.com/shoutcast/tools/sc_serv2_linux_x64-latest.tar.gz
tar -xzf sc_serv2_linux_x64-latest.tar.gz
```

## Troubleshooting

1. **No audio**: Check if source is connected in admin panel
2. **Connection refused**: Verify firewall and Icecast is running
3. **Audio stuttering**: Increase buffer size or check network
