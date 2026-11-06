#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --qos=gpu
#SBATCH --gres=gpu:l4_gpu:1
#SBATCH --mem=50G
#SBATCH --time=08:00:00
#SBATCH --job-name=jupyter-lab
#SBATCH --output=jupyter-lab-%j.log

# Update these variables before running the script
MINICONDA_PATH="/path/to/your/miniconda3"
ENV="example_env"

# Unused port between 8000 and 9999
port="$(comm -23 <(seq 8000 9999) \
    <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | grep "[0-9]\{1,5\}" | sort -u) | shuf -n 1)"
readonly port
if [[ -z "${port}" ]]; then
    echo "ERROR: no free port found between 8000 and 9999" >&2
    exit 1
fi
node="$(hostname).int.cemm.at"
readonly node

host "${node}"

# Activate your environment
echo "Activating environment"
source "${MINICONDA_PATH}"/bin/activate "${ENV}"

# Start jupyterlab session
jupyter lab --no-browser --port="${port}" --ip="${node}"
