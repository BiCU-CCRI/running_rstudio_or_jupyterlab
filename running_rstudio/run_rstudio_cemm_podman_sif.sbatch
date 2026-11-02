#!/bin/bash
#SBATCH --job-name=rstudio_podman_sif
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=25G
#SBATCH --time=06:00:00
#SBATCH --output=rstudio_podman_sif_%j.log # Slurm writes everything to --output if --error <error_output> is not set

set -euo pipefail

# Run the script with:
#     SLURM_UMASK=0077 sbatch run_rstudio_cemm_podman_sif.sbatch
#  to ensure group and others cannot see your password in the log file but the 
#  files produced by the script have default `umask` settings

set -euo pipefail

umask 0007

workdir="$(pwd -P)"

R_VERSION="4.4.2"
IMAGE_NAME="tidyverse-4.4-jdk"
RSTUDIO_IMAGE_SIF="/research/lab_ccri_bicu/public/apptainer_images/${IMAGE_NAME}.sif"

# Other common SLURM variables https://docs.hpc.shef.ac.uk/en/latest/referenceinfo/scheduler/SLURM/SLURM-environment-variables.html#gsc.tab=0
echo "======================"
echo "Working directory:     ${SLURM_SUBMIT_DIR}"
echo "Job name:              ${SLURM_JOB_NAME}"
echo "Job id:                ${SLURM_JOB_ID}"
echo "Job queue (partition): ${SLURM_JOB_PARTITION}"
echo "Job tasks, CPUs per task: ${SLURM_NTASKS}, ${SLURM_CPUS_PER_TASK}"
echo "Job RAM:               ${SLURM_MEM_PER_NODE}"
echo "Job node name:         ${SLURM_NODELIST}"
echo "Job node address:      $(nslookup "$(hostname)" | grep Name: | cut -f2)"
echo "Job node IP address:   $(nslookup "$(hostname)" | grep Address: | tail -1 | cut -d' ' -f2)"
echo "======================"

module load podman/5.8.6-GCCcore-14.3.0

# Host-side scratch space
host_tmpdir="$(mktemp -d -p "${TMPDIR:-/tmp}")"
cleanup() {
    rm -rf "${host_tmpdir}"
}
trap cleanup EXIT
trap 'exit 143' TERM INT

# Runtime directories for rootless Podman (Slurm jobs have no systemd user session)
XDG_RUNTIME_DIR="${host_tmpdir}/podman_runtime_$(id -u)"
PODMAN_TMPDIR="${host_tmpdir}/podman_tmp"
export XDG_RUNTIME_DIR PODMAN_TMPDIR
mkdir -m 700 "${XDG_RUNTIME_DIR}" "${PODMAN_TMPDIR}"

rstudio_config_dir="${workdir}/.rstudio_server"

mkdir -p -m 700 "${rstudio_config_dir}/run" "${rstudio_config_dir}/tmp" \
    "${rstudio_config_dir}/var/lib/rstudio-server" "${rstudio_config_dir}/var/run/rstudio-server" \
    "${rstudio_config_dir}/R/${R_VERSION}" "${rstudio_config_dir}/db"

# Create SQLite DB config to prevent rserver initialization crashes
cat >"${rstudio_config_dir}/db.conf" <<END
provider=sqlite
directory=${rstudio_config_dir}/db
END

# R Session Configuration File https://docs.posit.co/ide/server-pro/reference/rsession_conf.html
cat >"${rstudio_config_dir}/rsession.conf" <<END
# Set R_LIBS_USER to a path specific to rocker/rstudio to avoid conflicts with personal libraries from any R installation in the host environment
r-libs-user=${rstudio_config_dir}/R/${R_VERSION}
session-timeout-minutes=0
session-default-working-dir=${workdir}
END

# Send rserver logs to stderr so they end up in the Slurm log (debugging)
cat >"${rstudio_config_dir}/logging.conf" <<END
[*]
log-level=debug
logger-type=stderr
END

# .Rprofile and default functions
cat >"${rstudio_config_dir}/.Rprofile" <<END
source("${rstudio_config_dir}/.Ractivate.R")
END

# Location of .Rprofile - project-wide
# TMPDIR must be a path that exists INSIDE the container. /tmp in the container
#  is the bind mount of ${rstudio_config_dir}/tmp, so do not use the host TMPDIR here.
cat >"${workdir}/.Renviron" <<END
R_PROFILE_USER="${rstudio_config_dir}/.Rprofile"
TMPDIR="/tmp"
TMP="/tmp"
END

# Functions to load at startup
cat >"${rstudio_config_dir}/.Ractivate.R" <<END
save_session <- function() {
    savehistory(file = "~/.Rhistory")
    save.image(file = "~/.RData")
    cat("Session saved at", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
}
END

# Session secrets. PASSWORD is passed to the container by name (-e PASSWORD),
#  so it does not show up in the process list.
PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 20)"
export PASSWORD
USER_NAME="$(whoami)"

# Bind mounts for the container
PODMAN_BIND=(
    -v "${rstudio_config_dir}/run:/run" \
    -v "${rstudio_config_dir}/tmp:/tmp" \
    -v "${workdir}:/home/${USER_NAME}" \
    -v "${rstudio_config_dir}/rsession.conf:/etc/rstudio/rsession.conf" \
    -v "${rstudio_config_dir}/logging.conf:/etc/rstudio/logging.conf" \
    -v "${rstudio_config_dir}/var/lib/rstudio-server:/var/lib/rstudio-server" \
    -v "${rstudio_config_dir}/var/run/rstudio-server:/var/run/rstudio-server" \
    -v "${rstudio_config_dir}:${rstudio_config_dir}" \
    -v /nobackup:/nobackup \
    -v /research:/research:ro \
    -v "${workdir}:${workdir}"
)

# Unused port between 8000 and 9999
PORT="$(comm -23 <(seq 8000 9999) \
    <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | grep "[0-9]\{1,5\}" | sort -u) | shuf -n 1)"
readonly PORT
if [[ -z "${PORT}" ]]; then
    echo "ERROR: no free port found between 8000 and 9999" >&2
    exit 1
fi
NODE_ADDRESS="$(hostname).int.cemm.at"
readonly NODE_ADDRESS

echo "======================"
echo "Job started at: $(date)"

cat 1>&2 <<END

To access the RStudio Server, cmd + click for Mac/ctrl + click for Windows the link or copy-paste this to your web browser:
    http://${NODE_ADDRESS}:${PORT}
with:
    Rstudio user: ${USER_NAME}
    RStudio password: ${PASSWORD}

Note: You might have to wait a couple minutes for the RStudio Server to start up before you can log in.

END

# Launch RStudio using Podman with a SIF image archive. The container will be removed after the job ends.
#    --user "$(id -u):$(id -g)" \ # Do not use this or you will get "Error: OCI runtime error: runc: runc create failed: unable to start container process: error during container init: unable to setup user: cannot setgid to unmapped gid 20800 in user namespace" error
#    --userns=keep-id \ # Do not use this or you will get "Error: OCI runtime error: runc: runc create failed: unable to start container process: error during container init: unable to setup user: cannot setgid to unmapped gid 20800 in user namespace" error
podman --cgroup-manager=cgroupfs run --rm \
    --group-add keep-groups \
    --net=host \
    -e "USER=${USER_NAME}" \
    -e PASSWORD \
    -e RSTUDIO_SESSION_TIMEOUT=0 \
    "${PODMAN_BIND[@]}" \
    sif:"${RSTUDIO_IMAGE_SIF}" \
    rserver --www-port "${PORT}" \
    --server-user="${USER_NAME}" \
    --auth-none=0 \
    --auth-pam-helper-path=pam-helper \
    --auth-stay-signed-in-days=30 \
    --auth-timeout-minutes=0 \
    --server-data-dir=/var/run/rstudio-server \
    --database-config-file="${rstudio_config_dir}/db.conf"

echo "Job finished at: $(date)"

echo "Job stats:"
seff "${SLURM_JOB_ID}"
echo "======================"
