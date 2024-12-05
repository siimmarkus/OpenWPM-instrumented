FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

# Update ubuntu and setup conda
# adapted from: https://hub.docker.com/r/conda/miniconda3/dockerfile
RUN sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list

RUN apt-get update -y
# Install GUI and VNC


RUN apt-get clean -qq \
    && rm -r /var/lib/apt/lists/* -vf \
    && apt-get clean -qq \
    && apt-get update -qq \
    && apt-get upgrade -qq \
    # git and make for `npm install`, wget for `install-mamba`
    && apt-get install wget git make -qq \
    # deps to run firefox inc. with xvfb
    && apt-get install firefox xvfb libgtk-3-dev libasound2 libdbus-glib-1-2 libpci3 -qq

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y x11vnc

ENV HOME /opt
COPY scripts/install-mamba.sh .
RUN ./install-mamba.sh
ENV PATH $HOME/mamba/bin:$PATH

# Install OpenWPM
WORKDIR /opt/OpenWPM
COPY . .
RUN ./install.sh
ENV PATH $HOME/mamba/envs/openwpm/bin:$PATH

# Move the firefox binary away from the /opt/OpenWPM root so that it is available if
# we mount a local source code directory as /opt/OpenWPM
RUN mv firefox-bin /opt/firefox-bin
ENV FIREFOX_BINARY /opt/firefox-bin/firefox-bin

# Debugging why VNC is not working
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip x11vnc fluxbox gnome-terminal dbus-x11 xvfb libpq-dev

# Setting demo.py as the default command
#CMD ["python", "demo.py", "--domainfile", "domains.txt"]

# x11vnc and OpenWPM use the DISPLAY env variable to decide which display to use
ENV DISPLAY=:99
ENTRYPOINT Xvfb $DISPLAY -ac & x11vnc -forever -passwdfile $VNC_PASSWORD_FILE & python demo.py --domainfile domains.txt
