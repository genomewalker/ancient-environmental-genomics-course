set -e
# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &


# Install extensions for bash, python, and R
/tmp/code-server/bin/code-server --install-extension REditorSupport.r
/tmp/code-server/bin/code-server --install-extension ms-python.python

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

  cat <<EOF >/tmp/day1.yml
name: day1
channels:
  - conda-forge
  - bioconda
  - defaults
  - genomewalker
dependencies:
  - python=3.9
  - mapdamage2
  - fastp
  - htslib
  - samtools
  - bwa
  - bowtie2
  - bcftools
  - Adapterremoval
  - Picard
  - fastqc
EOF



  cat <<EOF >/tmp/day2.yml
name: day2
channels:
  - conda-forge
  - bioconda
  - defaults
  - genomewalker
dependencies:
  - python=3.9
  - snp-sites 
  - beast2
  - mafft
  - angsd
  - fastp
  - vsearch
  - raxML 
  - seqtk 
  - bowtie2
  - bwa
  - samtools
  - htslib
  - ngsLCA
  - r
  - r-optparse
  - r-phytools
  - r-scales
  - libcurl
  - cxx-compiler
  - c-compiler
  - bzip2
  - xz
  - zlib
  - libdeflate
  - openssl  # [not osx]
  - gsl
  - pip
  - pip:
      - bam-filter
EOF


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

  cat <<EOF >/tmp/mapping.yml
name: day4
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.9
  - bedtools
  - mapdamage2
  - plink
  - eigensoft
EOF

  cat <<EOF >/tmp/r.yml
name: r
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.9
  - r
  - radian
  - r-languageserver
  - r-httpgd
  - r-showtext
  - r-cpp
  - r-tidyverse
  - r-igraph
  - r-plotly
  - r-ggrepel
  - r-viridis
  - bioconductor-rsamtools
EOF


  mamba create -y -n course python=3.9
  mamba env create -f /tmp/r.yml
  rm /tmp/r.yml
  mamba env create -f /tmp/day1.yml
  rm /tmp/day1.yml
  mamba env create -f /tmp/day2.yml
  rm /tmp/day2.yml
  mamba env create -f /tmp/day4.yml
  rm /tmp/day4.yml
  mamba env create -f /tmp/microbes.yml
  rm /tmp/microbes.yml
  mamba env create -f /tmp/mapping.yml
  rm /tmp/mapping.yml

  echo "conda activate course" >>/home/${username}/.bashrc

  cat <<EOF >/home/${username}/.Rprofile
Sys.setenv(TERM_PROGRAM="vscode")
if (interactive() && Sys.getenv("RSTUDIO") == "") {
  source(file.path(Sys.getenv("HOME"), ".vscode-R", "init.R"))
}

if (interactive() && Sys.getenv("TERM_PROGRAM") == "vscode") {
  showtext::showtext_auto()
  if ("httpgd" %in% .packages(all.available = TRUE)) {
    options(vsc.plot = FALSE)
    options(device = function(...) {
      httpgd::hgd(silent = TRUE)
      .vsc.browser(httpgd::hgd_url(history = FALSE), viewer = "Beside")
    })
  }
}

EOF

mkdir -p /home/${username}/.local/share/code-server/User
cat <<EOF >/home/${username}/.local/share/code-server/User/settings.json
{
    "r.plot.useHttpgd": true,
    "r.rpath.linux": "/home/${username}/opt/conda/envs/r/bin/R",
    "r.rterm.linux": "/home/${username}/opt/conda/envs/r/bin/radian",
    "r.bracketedPaste": true,
    "r.rterm.option": [
        "--no-save",
        "--no-restore",
        "--r-binary=/home/antonio/opt/conda/envs/r/bin/R"
    ],
    "r.alwaysUseActiveTerminal": true,
}
EOF


# Compile different tools
conda activate day2
cd /home/${username}/opt
mkdir src
cd src
git clone https://github.com/samtools/htslib.git
cd htslib
git submodule update --init --recursive
make CPPFLAGS="-L$${CONDA_PREFIX}/lib -I$${CONDA_PREFIX}/include"
cd ..
git clone https://github.com/richarddurbin/phynder.git
cd phynder
make 
mv phynder /home/antonio/opt/conda/envs/day2/bin/
cd ..
git clone https://github.com/ruidlpm/pathPhynder.git
cd pathPhynder
mv pathPhynder.R /home/antonio/opt/conda/envs/day2/bin/
cat <<EOF >/home/${username}/opt/conda/envs/day2/bin/pathPhynder
#!/bin/bash
Rscript /home/antonio/opt/conda/envs/day2/bin/pathPhynder.R "\$@"
EOF
chmod +x /home/${username}/opt/conda/envs/day2/bin/pathPhynder
cd ..
git clone --recurse-submodules https://github.com/fbreitwieser/bamcov
cd bamcov
make CPPFLAGS="-L$${CONDA_PREFIX}/lib -I$${CONDA_PREFIX}/include"
mv bamcov /home/antonio/opt/conda/envs/day2/bin/
cd ..
rm -rf pathPhynder phynder bamcov htslib

conda deactivate

conda activate r

Rscript -e 'remotes::install_github("uqrmaie1/admixtools")'

conda deactivate



fi
. /home/${username}/.bash_profile


