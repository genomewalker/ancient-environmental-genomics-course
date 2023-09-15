set -e
# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

#coder dotfiles -y ${dotfiles_url} &

echo ". /home/${username}/.bashrc" >>/home/${username}/.bash_profile

wget -O /home/${username}/.bashrc https://raw.githubusercontent.com/genomewalker/dotfiles/master/shell/bash/.bashrc

. /home/${username}/.bash_profile

if [ ! -d /home/${username}/opt ]; then

  mkdir /home/${username}/opt
  wget -O /tmp/Mambaforge.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
  bash /tmp/Mambaforge.sh -b -p /home/${username}/opt/conda

  source /home/${username}/opt/conda/etc/profile.d/conda.sh

  conda init bash

  . /home/${username}/.bash_profile

  conda config --set auto_activate_base false
  conda config --add channels defaults
  conda config --add channels bioconda
  conda config --add channels conda-forge
  conda config --set channel_priority strict

  cat <<EOF >/tmp/microbes.yml
name: day5-taxonomy
channels:
  - conda-forge
  - bioconda
  - defaults
  - genomewalker
dependencies:
  - python=3.9
  - bowtie2
  - seqkit
  - csvtk
  - taxonkit
  - samtools>=1.14
  - picard
  - mawk
  - cxx-compiler
  - pip
  - pip:
      - bam-filter
EOF

  cat <<EOF >/tmp/mapping.yml
name: day2-mapping
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.9
  - bowtie2
  - seqkit
  - csvtk
  - samtools>=1.14
EOF

  mamba create -y -n course python=3.9
  mamba env create -f /tmp/microbes.yml
  rm /tmp/microbes.yml
  mamba env create -f /tmp/mapping.yml
  rm /tmp/mapping.yml

  echo "conda activate course" >>/home/${username}/.bashrc
fi
. /home/${username}/.bash_profile
