FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV WINEPREFIX=/root/.wine
ENV WINEDEBUG=-all
ENV PYTHONUNBUFFERED=1

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
      wine32 wine64 xvfb x11vnc novnc websockify fluxbox \
      wget curl net-tools ca-certificates python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mt5setup.exe /app/mt5setup.exe
COPY app/main.py /app/main.py
COPY docker/entrypoint.sh /app/entrypoint.sh

RUN pip3 install --no-cache-dir fastapi uvicorn && \
    chmod +x /app/entrypoint.sh && \
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

EXPOSE 8080 8000
CMD ["/app/entrypoint.sh"]
