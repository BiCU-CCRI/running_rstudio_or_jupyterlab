#!/bin/bash
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time 12:00:00
#SBATCH --job-name rstudio-singularity
#SBATCH --output rstudio-singularity-%j.log

module load singularity

# set the work directory to your group
# set the version to the version that you pulled
workdir=$(pwd)
version=4.4
singularityimage=/nobackup/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif

mkdir -p -m 700 ${workdir}/run ${workdir}/tmp ${workdir}/var/lib/rstudio-server ${workdir}/R/$version

cat > ${workdir}/rsession.conf <<END
# R Session Configuration File

r-libs-user=${workdir}/R/%v
session-timeout-minutes=0
END

# Set R_LIBS_USER to a path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

export SINGULARITY_BIND="${workdir}/run:/run,${workdir}/tmp:/tmp,${workdir}/rsession.conf:/etc/rstudio/rsession.conf,${workdir}/var/lib/rstudio-server:/var/lib/rstudio-server,${workdir}/run:/var/run,/nobackup:/nobackup,/research:/research,${workdir}:/home/$(whoami)"

# Do not suspend idle sessions.
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export SINGULARITYENV_RSTUDIO_SESSION_TIMEOUT=0
export SINGULARITYENV_USER=${USER}
export SINGULARITYENV_PASSWORD='test1'

# Get unused socket per https://unix.stackexchange.com/a/132524
# Tiny race condition between the python & singularity commands
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
# Get node IP address.
readonly ADD=$(nslookup `hostname` | grep -i address | awk -F" " '{print $2}' | awk -F# '{print $1}' | tail -n 1)

cat 1>&2 <<END
"Running RStudio at $ADD:$PORT"
END

singularity exec --cleanenv ${singularityimage} \
    rserver --www-port ${PORT} \
            --server-user=$(whoami) \
            --auth-none=0 \
            --auth-pam-helper-path=pam-helper

