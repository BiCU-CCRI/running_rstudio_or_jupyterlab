#!/bin/bash
#SBATCH --job-name=rstudio_podman
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=25G
#SBATCH --time=06:00:00
#SBATCH --output=logs/rstudio_podman_%j.log # Slurm writes everything to --output if --error logs/rstudio_podman_%j.err is not set

set -euo pipefail

workdir="$(pwd -P)"

R_VERSION="4.4.2"
IMAGE_NAME="r_4.4.2_tidyverse_jdk_dev"
IMAGE_TAG="latest"
IMAGE_TAR="/nobackup/lab_ccri_bicu/internal/joppelt/BiCU-CCRI/jo005_emilia_rnaseq/envs/${IMAGE_NAME}-${IMAGE_TAG}.tar"

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

# Host-side scratch space for Podman only
host_tmpdir="$(mktemp -d -p "${TMPDIR:-/tmp}")"
cleanup() {
    rm -rf "${host_tmpdir}"
}
trap cleanup EXIT
trap 'exit 143' TERM INT

# Runtime directories for rootless Podman (Slurm jobs have no systemd user session)
export XDG_RUNTIME_DIR="${host_tmpdir}/podman_runtime_$(id -u)"
export PODMAN_TMPDIR="${host_tmpdir}/podman_tmp"
mkdir -p -m 700 "${XDG_RUNTIME_DIR}" "${PODMAN_TMPDIR}"

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

Note: You might have to wait approx. a minute for the RStudio Server to start up before you can log in.

END

# Launch the RStudio using Podman and tar image archive. The container will be removed after the job ends.
podman --cgroup-manager=cgroupfs run --rm \
    --userns=keep-id \
    --net=host \
    -e "USER=${USER_NAME}" \
    -e PASSWORD \
    -e RSTUDIO_SESSION_TIMEOUT=0 \
    -v "${rstudio_config_dir}/run:/run" \
    -v "${rstudio_config_dir}/tmp:/tmp" \
    -v "${rstudio_config_dir}/rsession.conf:/etc/rstudio/rsession.conf" \
    -v "${rstudio_config_dir}/logging.conf:/etc/rstudio/logging.conf" \
    -v "${rstudio_config_dir}/var/lib/rstudio-server:/var/lib/rstudio-server" \
    -v "${rstudio_config_dir}/var/run/rstudio-server:/var/run/rstudio-server" \
    -v "${rstudio_config_dir}:${rstudio_config_dir}" \
    -v "${workdir}:/home/${USER_NAME}" \
    -v /nobackup:/nobackup \
    -v /research:/research \
    docker-archive:"${IMAGE_TAR}" \
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
