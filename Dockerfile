FROM python:3.9-slim

VOLUME [ "/tmp/RFQuack" ]

LABEL maintainer "RFQuack"

# TODO maybe library.json does the job already and this is not needed
ENV NANOPB_URL="https://github.com/nanopb/nanopb/archive/master.zip"

WORKDIR /tmp

# Install RFQuack as library.
COPY . RFQuack

# Install stuff
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git \
    wget \
    unzip \
    make \
    protobuf-compiler \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/* \
  && pip install -U pip \
  && pip install -r /tmp/RFQuack/requirements.pip \
  && platformio platform install espressif32

# NOTE: platformio will **COPY** the library to its private folder.
RUN wget -O /tmp/nanopb.zip ${NANOPB_URL} \
  && mkdir /tmp/RFQuack/lib \
  && unzip -d /tmp/RFQuack/lib/nanopb /tmp/nanopb.zip

RUN platformio lib -g install file:///tmp/RFQuack \
  && cd $HOME/.platformio/lib/RFQuack/ \
  && make proto

# TODO add build examples as a simple regression test here

# Add project files
WORKDIR /quack
COPY docker/project .

COPY docker/my-entrypoint.sh /my-entrypoint.sh

ENTRYPOINT ["/bin/sh"]
CMD ["/my-entrypoint.sh"]
