#!/bin/bash
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time 12:00:00
#SBATCH --job-name rstudio-singularity
#SBATCH --output rstudio-singularity-%j.log

# How to use the script:
# launch this file with
# bash run_rstudio_ccri_4.4-java.sh
#
# Establish ssh connection with port forwarding:
# ssh -L localhost:<port>:10.110.81.2:<port> <name>@login.int.cemm.at

module load singularity

# set the work directory to your group
# set the version to the version that you pulled
workdir=$(pwd)
version=4.4
singularityimage=/nobackup/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif
dotconfig=$(pwd)/.config/rstudio
path_renv_host=/nobackup/lab_ccri_bicu/public/resources/renv_cache/

#mkdir -p -m 700 ${workdir}/run ${workdir}/tmp ${workdir}/var/lib/rstudio-server ${workdir}/R/$version

mkdir -p -m 700 ${workdir}/RStdServr/run
mkdir -p -m 700 ${workdir}/RStdServr/tmp
mkdir -p -m 700 ${workdir}/RStdServr/renv
mkdir -p -m 700 ${workdir}/RStdServr/var/lib/rstudio-server
mkdir -p -m 700 ${workdir}/RStdServr/R/$version

#cat > ${workdir}/rsession.conf <<END
## R Session Configuration File
#
#r-libs-user=${workdir}/R/%v
#session-timeout-minutes=0
#END

# Set R_LIBS_USER to a path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

export SINGULARITY_BIND="${workdir}/RStdServr/run:/run,${workdir}/RStdServr/tmp:/tmp,${dotconfig}:/home/${USER}/.config/rstudio,${workdir}/RStdServr/var/lib/rstudio-server:/var/lib/rstudio-server,${workdir}/RStdServr/run:/var/run,${path_renv_host}/:${workdir}/RStdServr/renv,${workdir}:/home/$(whoami)"

# Do not suspend idle sessions.
# alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export SINGULARITYENV_RSTUDIO_SESSION_TIMEOUT=0
export SINGULARITYENV_USER=${USER}
export SINGULARITYENV_PASSWORD='test0'

# Get unused socket per https://unix.stackexchange.com/a/132524
# Tiny race condition between the python & singularity commands
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
# Get node IP address.
readonly ADD=$(nslookup $(hostname) | grep -i address | awk -F" " '{print $2}' | awk -F# '{print $1}' | tail -n 1)

cat 1>&2 <<END
"Running RStudio at $ADD:$PORT"
END

singularity exec --cleanenv ${singularityimage} \
	rserver --www-port ${PORT} \
	--server-user=$(whoami) \
	--auth-none=0 \
	--auth-pam-helper-path=pam-helper
