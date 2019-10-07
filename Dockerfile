# axivity linux test environment. anaconda version, which is also suggested by the https://github.com/activityMonitoring/biobankAccelerometerAnalysis.
FROM ubuntu:xenial
  
ARG USERNAME=ruser
ARG USERHOME=/home/ruser
ARG USERID=1000
ARG USERGECOS=ruser




RUN adduser \
  --home "$USERHOME" \
  --uid $USERID \
  --gecos "$USERGECOS" \
  --disabled-password \
  "$USERNAME"


ENV TZ 'Europe/London'
RUN echo $TZ > /etc/timezone && \
apt-get update && apt-get install -y tzdata && \
rm /etc/localtime && \
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
dpkg-reconfigure -f noninteractive tzdata


RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    wget \
 && apt-get clean
 #&& rm -rf /var/lib/apt/lists/*
RUN apt-get install -y supervisor screen vim


RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen


# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=ruser \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/ruser



# Create ruser user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN groupadd wheel -g 11 && \
    mkdir -p $CONDA_DIR && \
    chown ruser:ruser $CONDA_DIR 

USER ruser


# Install conda as ruser and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.7.10
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "1c945f2b3335c7b2b15130b1b2dc5cf4 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge


RUN $CONDA_DIR/bin/conda config --system --set auto_update_conda false

RUN $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda install --quiet --yes conda="${MINICONDA_VERSION%.*}.*"

RUN $CONDA_DIR/bin/conda update --all --quiet --yes
RUN conda clean -tipsy
RUN rm -rf /home/ruser/.cache/yarn


#requirements for axivity test environment
#RUN conda install  argparse 
RUN conda install  joblib 
RUN conda install  matplotlib 
RUN conda install  numpy 
RUN conda install  pandas 
RUN conda install  scikit-learn  
RUN conda install  sphinx 
RUN conda install  sphinx_rtd_theme 
RUN conda install  statsmodels

USER root

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh
COPY bootstrap.supervisor.conf /etc/supervisor/conf.d/supervisord.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf

#USER ruser
#RUN python3.7 -m pip install argparse 
#RUN python3.7 -m pip install joblib 
#RUN python3.7 -m pip install matplotlib 
#RUN python3.7 -m pip install numpy 
#RUN python3.7 -m pip install pandas 
#RUN python3.7 -m pip install sklearn 
#RUN python3.7 -m pip install sphinx 
#RUN python3.7 -m pip install sphinx-rtd-theme 
#RUN python3.7 -m pip install statsmodels


USER root
CMD  ["/usr/bin/supervisord"]

