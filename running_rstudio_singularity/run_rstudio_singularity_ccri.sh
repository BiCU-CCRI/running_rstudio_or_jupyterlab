#!/bin/bash

set -ueo pipefail

# Specify the path to your working directory; can be $(pwd) if you run the script from your working directory
workdir=$(pwd -P)

# Set the R version of your RStudio Server R version
r_version='4.3'
# Specify the RStudio Server singularity image file name
rstudio_singularity_image=/home/$(whoami)/bioinf_isilon/core_bioinformatics_unit/Public/singularity_images/ccribioinf_dockrstudio_4.2.0-v1.sif

rstudio_server_config_dir="${workdir}/.rstudio_server"

mkdir -p -m 700 "${rstudio_server_config_dir}/run" "${rstudio_server_config_dir}/tmp" "${rstudio_server_config_dir}/var/lib/rstudio-server" \
    "${rstudio_server_config_dir}/R/${r_version}"

# R Session Configuration File https://docs.posit.co/ide/server-pro/reference/rsession_conf.html
cat >"${rstudio_server_config_dir}/rsession.conf" <<END
# Set R_LIBS_USER to a path specific to rocker/rstudio to avoid conflicts with personal libraries from any R installation in the host environment
r-libs-user=${rstudio_server_config_dir}/R/${r_version}
session-timeout-minutes=0
session-default-working-dir=${workdir}
END

export SINGULARITY_BIND="${rstudio_server_config_dir}/run:/run,${rstudio_server_config_dir}/tmp:/tmp,\
${rstudio_server_config_dir}/rsession.conf:/etc/rstudio/rsession.conf,${rstudio_server_config_dir}/var/lib/rstudio-server:/var/lib/rstudio-server,\
${rstudio_server_config_dir}/run:/var/run,\
${rstudio_server_config_dir}:${rstudio_server_config_dir},\
/scratch:/scratch,/home:/home"

# Do not suspend idle sessions
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export SINGULARITYENV_RSTUDIO_SESSION_TIMEOUT=0
export SINGULARITYENV_USER="$(whoami)"
export SINGULARITYENV_PASSWORD='rstudio4_3_2_test1!'

# Get unused socket
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
readonly HOSTIP=$(hostname -I | cut -d' ' -f1)

cat 1>&2 <<END
To access the server, cmd + click for Mac/ctrl + click for Windows the link or copy-paste it to your web browser:
http://${HOSTIP}:${PORT}
END

singularity exec \
    --cleanenv "${rstudio_singularity_image}" \
    rserver --www-port "${PORT}" \
    --server-user="$(whoami)" \
    --auth-none=0 \
    --auth-pam-helper-path=pam-helper
