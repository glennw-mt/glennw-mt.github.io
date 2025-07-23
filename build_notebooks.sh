#!/bin/bash

# Configuration
HUGO_CONTENT_DIR="content"
HUGO_STATIC_DIR="static"

# Check if the content directory exists
if [ ! -d "$HUGO_CONTENT_DIR" ]; then
    echo "Error: Hugo content directory not found at $HUGO_CONTENT_DIR."
    exit 1
fi

# Go through the content directory to find all Jupyter notebooks
find "$HUGO_CONTENT_DIR" -name "*.ipynb" | while read -r notebook_path; do
    # Get the directory of the notebook
    notebook_dir=$(dirname "$notebook_path")
    # Get the filename without extension
    filename=$(basename -- "$notebook_path" .ipynb)

    echo "Processing notebook: $notebook_path"

    # Convert the notebook to Markdown
    # --output-dir is used to place the output in the same directory as the notebook.
    # --to markdown --NbConvertApp.output_files_dir=. ensures that image files are put in a separate folder (e.g., my-notebook_files).
    jupyter nbconvert --to markdown --output-dir="$notebook_dir" "$notebook_path"

    # The converted Markdown file and the images folder have been created in the same directory as the notebook.
    # Now, we need to handle the case where we don't want to use page bundles.
    # If you want to use the Page Bundle method (recommended), you can stop here.
    # The next steps are for the alternative approach: moving assets to the static folder.

    # -----------------
    # Alternative Method: Move assets to static folder and adjust paths
    # -----------------

    # Define the assets directory created by nbconvert
    notebook_assets_dir="$notebook_dir/${filename}_files"

    # Check if the assets directory exists
    if [ -d "$notebook_assets_dir" ]; then
        echo "Found assets directory: $notebook_assets_dir"

        # Determine the relative path from content to the notebook directory
        relative_path="${notebook_dir#$HUGO_CONTENT_DIR/}"

        # Define the destination directory in the static folder
        static_dest_dir="$HUGO_STATIC_DIR/$relative_path"
        
        # Define the path to the old assets folder in the static directory
        old_static_assets_dir="$static_dest_dir/${filename}_files"

        # If the old assets folder exists, remove it before moving the new one
        if [ -d "$old_static_assets_dir" ]; then
            echo "Removing old assets directory: $old_static_assets_dir"
            rm -rf "$old_static_assets_dir"
        fi

        echo "Creating static directory structure: $static_dest_dir"
        mkdir -p "$static_dest_dir"

        # Move the assets folder
        echo "Moving assets to: $static_dest_dir"
        mv -f "$notebook_assets_dir" "$static_dest_dir"
        
        # Now, we need to update the image paths in the generated Markdown file.
        markdown_file="$notebook_dir/$filename.md"
        
        if [ -f "$markdown_file" ]; then
            echo "Updating image paths in: $markdown_file"
            
            # The sed command finds and replaces the relative image paths.
            # We use a non-standard delimiter (|) to avoid issues with '/' in paths.
            # The replacement path is /the/relative/path/your-notebook_files/image.png
            sed -i "s|${filename}_files|/${relative_path}/${filename}_files|" "$markdown_file"
        fi
    fi

done

echo "Notebook conversion and asset management complete."