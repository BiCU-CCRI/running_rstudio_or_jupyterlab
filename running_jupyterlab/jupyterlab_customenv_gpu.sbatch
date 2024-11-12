#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --qos=gpu
#SBATCH --mem=50G
#SBATCH --time 08:00:00
#SBATCH --job-name jupyter-lab
#SBATCH --output jupyter-lab-%j.log
#SBATCH --gres=gpu:l4_gpu:1

# get tunneling info
port=$(shuf -i8000-9999 -n1)
node=$(hostname).int.cemm.at
user=$(whoami)

host ${node}

# activate your environment
echo "Activating environment"
source /nobackup/lab_boztug/projects/ccasey/miniconda3/bin/activate simclr_test

# start jupyterlab session
jupyter lab --no-browser --port=${port} --ip=${node}