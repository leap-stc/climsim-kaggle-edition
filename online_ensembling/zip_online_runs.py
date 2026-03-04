import os
import shutil
import glob
import subprocess

# Define the base directory and patterns
BASE_DIR = '/pscratch/sd/j/jerrylin/hugging/E3SM-MMF_ne4/online_runs/climsim3_ensembles_good'

# The specific folders and properties requested
TARGET_FOLDERS = ['standard', 'conf', 'diff', 'multirep', 'v6']
MODELS = ['unet', 'pure_resLSTM', 'pao_model', 'convnext', 'encdec_lstm']
SEEDS = ['7', '43', '1024']

# Provide a default regex range for years, e.g., 000[1-5] to match the first 5 years
YEARS_REGEXP = "1-5" 

# Target directory and name of the final archive to create
OUTPUT_DIR = 'subset_runs'
OUTPUT_ARCHIVE = 'subset_runs.tar.gz'

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    print(f"Copying files to {OUTPUT_DIR}/ ...")
    copied_count = 0

    for folder in TARGET_FOLDERS:
        for model in MODELS:
            for seed in SEEDS:
                # Based on the structure observed earlier (e.g., standard/five_year_runs/unet_seed_7)
                model_name_seed = f"{model}_seed_{seed}"
                
                # Most folders have intermediate 'five_year_runs'
                run_dir = os.path.join(BASE_DIR, folder, 'five_year_runs', model_name_seed, 'run')
                
                # Fallback if 'five_year_runs' doesn't exist just in case
                if not os.path.exists(run_dir):
                    run_dir = os.path.join(BASE_DIR, folder, model_name_seed, 'run')
                
                if not os.path.exists(run_dir):
                    print(f"Note: run directory not found for {folder}/{model_name_seed}")
                    continue

                # Expected pattern: {model_name}_seed_{seed}.eam.h0.000[{years_regexp}]*.nc
                search_pattern = os.path.join(run_dir, f"{model_name_seed}.eam.h0.000[{YEARS_REGEXP}]*.nc")
                matched_files = glob.glob(search_pattern)

                if matched_files:
                    dest_folder = os.path.join(OUTPUT_DIR, folder, model_name_seed)
                    os.makedirs(dest_folder, exist_ok=True)
                    
                    for filepath in matched_files:
                        filename = os.path.basename(filepath)
                        dest_path = os.path.join(dest_folder, filename)
                        
                        # Copy the file preserving metadata
                        shutil.copy2(filepath, dest_path)
                        copied_count += 1
                        
    print(f"Successfully copied {copied_count} files.")
    
    if copied_count > 0:
        print(f"Creating archive {OUTPUT_ARCHIVE}...")
        # Use simple tar command to compress the structured directory
        subprocess.run(['tar', '-czf', OUTPUT_ARCHIVE, OUTPUT_DIR])
        print(f"Created {OUTPUT_ARCHIVE}!")
    else:
        print("No files matched the specified patterns; skipping archive creation.")

if __name__ == "__main__":
    main()

