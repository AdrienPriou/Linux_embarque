# Based on Ubuntu "" x.y => Your version of Ubuntu or else!
FROM focal # Initializiation of image from focal Kernell

# LABEL about the custom image 
LABEL maintainer="adrien.priou@ynov.com" # Your Ynov Bordeaux Campus student email address
LABEL version="0.1" # First version, nothing to change!
LABEL description="docker_file" # Add a relevant description of the image here! (Recommended)

# Make the creation of docker images easier so that CTNG_UID/CTNG_GID have
# a default value if it's not explicitly specified when building. This
# will allow publishing of images on various package repositories (e.g.
# docker hub, gitlab containers). dmgr.sh can still be used to set the
# UID/GID to that of the current user when building a custom container.
ARG CTNG_UID=1000
ARG CTNG_GID=1000
# File to configure for your raspberry pi version
ARG CONFIG_FILE

# Crosstool-ng must be executed from a user that isn't the superuser (root)
# You must create a user and add it to the sudoer group
# Help : https://phoenixnap.com/kb/how-to-create-sudo-user-on-ubuntu
# https://phoenixnap.com/kb/how-to-create-sudo-user-on-ubuntu
RUN groupadd -g $CTNG_GID ctool-ng
RUN useradd -d /home/ctool-ng -m -g $CTNG_GID -u $CTNG_UID -s /bin/bash ctool-ng
# You will need to update the repository list before updating your system in order to install some of the packages
# Use the sources.list provided with the lab materials
# On ubuntu, lookup the command add-apt-repository and the repos universe and multiverse?
RUN apt-get -y install software-properties-common 
RUN add-apt-repository universe

RUN apt-get -y update && apt-get -y upgrade 

# Install necessary packages to run crosstool-ng
# You don't remember the previous lectures on the crosstool-ng?
# Use google : install crosstool-ng <Your distribution>??
RUN apt-get install -y gcc g++ bison flex texinfo install-info info make \
libncurses5-dev python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils patch libstdc++6 rsync git unzip help2man
# Install Dumb-init
# https://github.com/Yelp/dumb-init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 && \
echo "057ecd4ac1d3c3be31f82fc0848bf77b1326a975b4f8423fe31607205a0fe945  /usr/local/bin/dumb-init" | sha256sum -c - && \
chmod 755 /usr/local/bin/dumb-init
RUN echo 'export PATH=/opt/ctool-ng/bin:$PATH' >> /etc/profile
ENTRYPOINT [ "/usr/local/bin/dumb-init", "--" ]

# Login with user
USER ctool-ng
WORKDIR /home/ctool-ng
# Download and install the latest version of crosstool-ng
# https://github.com/crosstool-ng/crosstool-ng.git
RUN git clone -b master --single-branch --depth 1 \
    https://github.com/crosstool-ng/crosstool-ng.git ct-ng
WORKDIR /home/ctool-ng/ct-ng
RUN ./bootstrap
ENV PATH=/home/ctool-ng/.local/bin:$PATH
COPY ${CONFIG_FILE} config
# Build crosstool-ng
RUN ./configure --prefix=/home/ctool-ng/.local
RUN make
RUN make install

ENV TOOLCHAIN_PATH=/home/dev/x-tools/${CONFIG_FILE}
ENV PATH=${TOOLCHAIN_PATH}/bin:$PATH

CMD ["bash"]
