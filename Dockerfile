# syntax=docker.io/docker/dockerfile:1.7-labs
# Syntax declaration to be able to use --exclude flag on COPY

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

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y x11vnc jq

ENV HOME /opt
COPY scripts/install-mamba.sh .
RUN ./install-mamba.sh
ENV PATH $HOME/mamba/bin:$PATH

# Install OpenWPM
WORKDIR /opt/OpenWPM
#COPY . .
COPY --exclude=entrypoint.sh --exclude=demo.py . .
RUN ./install.sh
ENV PATH $HOME/mamba/envs/openwpm/bin:$PATH

# Move the firefox binary away from the /opt/OpenWPM root so that it is available if
# we mount a local source code directory as /opt/OpenWPM
RUN mv firefox-bin /opt/firefox-bin
ENV FIREFOX_BINARY /opt/firefox-bin/firefox-bin

# Copy these in a later layer to speed up container recreation
COPY demo.py entrypoint.sh ./


# x11vnc and OpenWPM use the DISPLAY env variable to decide which display to use
ENV DISPLAY=:99
ENTRYPOINT ./entrypoint.sh
