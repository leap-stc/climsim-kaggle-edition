#!/bin/bash
#SBATCH --job-name=zip_online_runs
#SBATCH -A m4334
#SBATCH -C cpu
#SBATCH -q regular
#SBATCH -t 4:00:00
#SBATCH --output=zip_online_runs_%j.out
#SBATCH --error=zip_online_runs_%j.err
#SBATCH -c 32
#SBATCH --mail-user=jerryL9@uci.edu
#SBATCH --mail-type=ALL

# Zip online ensemble runs into a tar.gz archive without copying files first.
# Uses pigz for parallel gzip compression and tar --transform to preserve
# directory structure in the archive without a staging step.
#
# Usage: sbatch zip_online_runs.sbatch [YEARS_RANGE]
#   YEARS_RANGE: glob character class for years, default "1-5" (matches 000[1-5])

set -euo pipefail

BASE_DIR="/pscratch/sd/j/jerrylin/hugging/E3SM-MMF_ne4/online_runs/climsim3_ensembles_good"
OUTPUT_ARCHIVE="${BASE_DIR}/subset_runs.tar.gz"
YEARS="${1:-1-5}"

FOLDERS=(standard conf diff multirep v6)
MODELS=(unet squeezeformer pure_resLSTM pao_model convnext encdec_lstm)
SEEDS=(7 43 1024)

# Build a file list for tar, using --transform to create clean archive paths
FILE_LIST=$(mktemp)
trap "rm -f $FILE_LIST" EXIT

count=0
for folder in "${FOLDERS[@]}"; do
    for model in "${MODELS[@]}"; do
        for seed in "${SEEDS[@]}"; do
            if [ "$folder" = "standard" ]; then
                case_name="${model}_seed_${seed}"
            else
                case_name="${model}_${folder}_seed_${seed}"
            fi

            run_dir="${BASE_DIR}/${folder}/five_year_runs/${case_name}/run"
            if [ ! -d "$run_dir" ]; then
                run_dir="${BASE_DIR}/${folder}/${case_name}/run"
            fi
            if [ ! -d "$run_dir" ]; then
                echo "Note: run directory not found for ${folder}/${case_name}"
                continue
            fi

            # Find matching h0 files and write to file list with transform-friendly paths
            for f in "${run_dir}/${case_name}".eam.h0.000["${YEARS}"]*.nc; do
                [ -e "$f" ] || continue
                echo "$f"
                count=$((count + 1))
            done

            # Find matching combined precip files if they exist
            if [ -d "${run_dir}/precip_dir" ]; then
                for f in "${run_dir}/precip_dir/combined"*.nc; do
                    [ -e "$f" ] || continue
                    echo "$f"
                    count=$((count + 1))
                done
            fi
        done
    done
done > "$FILE_LIST"

echo "Found ${count} files to archive."

if [ "$count" -eq 0 ]; then
    echo "No files matched; exiting."
    exit 0
fi

NTHREADS="${SLURM_CPUS_PER_TASK:-$(nproc)}"
echo "Creating ${OUTPUT_ARCHIVE} using pigz with ${NTHREADS} threads..."

# Use pigz for parallel compression. tar reads from file list and transforms
# paths so the archive has clean structure: folder/case_name/filename.nc
# The --transform strips the absolute path prefix per folder variant.
STRIPPED_BASE_DIR="${BASE_DIR#/}"
tar --use-compress-program="pigz -p ${NTHREADS}" \
    -cf "$OUTPUT_ARCHIVE" \
    --files-from="$FILE_LIST" \
    --transform="s|^${STRIPPED_BASE_DIR}/\([^/]*/\)\(five_year_runs/\)\?\([^/]*/\)run/|\1\3|"

archive_size=$(du -h "$OUTPUT_ARCHIVE" | cut -f1)
echo "Done! Created ${OUTPUT_ARCHIVE} (${archive_size}) with ${count} files."
