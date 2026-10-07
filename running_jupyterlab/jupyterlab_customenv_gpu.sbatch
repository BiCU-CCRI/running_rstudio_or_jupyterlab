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

# get tunneling info
port=$(shuf -i8000-9999 -n1)
node=$(hostname).int.cemm.at

host "${node}"

# Activate your environment
echo "Activating environment"
source "${MINICONDA_PATH}"/bin/activate "${ENV}"

# Start jupyterlab session
jupyter lab --no-browser --port="${port}" --ip="${node}"
