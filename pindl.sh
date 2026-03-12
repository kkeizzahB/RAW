cat > pinterest_downloader.sh << 'EOF'
#!/bin/bash

# Function to get CSRF token and cookies
get_snappin_token() {
    echo "Getting CSRF token and cookies..." >&2
    response=$(curl -s -i "https://snappin.app/")
    
    # Extract cookies from headers
    cookies=$(echo "$response" | grep -i "set-cookie" | sed 's/Set-Cookie: //i' | cut -d';' -f1 | tr '\n' ';' | sed 's/;$//')
    
    # Extract CSRF token from HTML body
    csrf_token=$(echo "$response" | grep -A5 -B5 'csrf-token' | grep 'content="' | sed 's/.*content="\([^"]*\).*/\1/')
    
    if [ -z "$csrf_token" ]; then
        # Alternative method to extract CSRF token
        csrf_token=$(echo "$response" | grep -o 'name="csrf-token"[^>]*content="[^"]*"' | sed 's/.*content="\([^"]*\).*/\1/')
    fi
    
    echo "$cookies|$csrf_token"
}

# Function to download from Pinterest
snappin_download() {
    pinterest_url="$1"
    
    echo "Processing: $pinterest_url" >&2
    
    # Get token and cookies
    token_data=$(get_snappin_token)
    cookies=$(echo "$token_data" | cut -d'|' -f1)
    csrf_token=$(echo "$token_data" | cut -d'|' -f2)
    
    if [ -z "$csrf_token" ] || [ -z "$cookies" ]; then
        echo '{"status": false, "message": "Failed to get CSRF token or cookies"}'
        return 1
    fi
    
    echo "CSRF Token: $csrf_token" >&2
    echo "Cookies: $cookies" >&2
    
    # Make POST request to download
    response=$(curl -s -i -X POST "https://snappin.app/" \
        -H "Content-Type: application/json" \
        -H "x-csrf-token: $csrf_token" \
        -H "Cookie: $cookies" \
        -H "Referer: https://snappin.app" \
        -H "Origin: https://snappin.app" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
        -d "{\"url\": \"$pinterest_url\"}")
    
    # Extract the response body
    body=$(echo "$response" | awk '/^\r$/{body=1; next} body')
    
    # Extract thumbnail URL
    thumb=$(echo "$body" | grep -o 'img[^>]*src="[^"]*"' | head -1 | sed 's/.*src="\([^"]*\).*/\1/')
    
    # Extract download links
    download_links=$(echo "$body" | grep -o 'a[^>]*href="[^"]*"[^>]*class="[^"]*is-success[^"]*"' | sed 's/.*href="\([^"]*\).*/\1/')
    
    video_url=""
    image_url=""
    
    # Check each download link
    for link in $download_links; do
        full_link="$link"
        if [[ ! "$link" =~ ^http ]]; then
            full_link="https://snappin.app$link"
        fi
        
        echo "Checking link: $full_link" >&2
        
        # Get content type using HEAD request
        content_type=$(curl -s -I "$full_link" | grep -i "content-type:" | head -1 | cut -d':' -f2- | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$link" == *"/download-file/"* ]]; then
            if [[ "$content_type" == *"video"* ]]; then
                video_url="$full_link"
                echo "Found video: $video_url" >&2
            elif [[ "$content_type" == *"image"* ]]; then
                image_url="$full_link"
                echo "Found image: $image_url" >&2
            fi
        elif [[ "$link" == *"/download-image/"* ]]; then
            image_url="$full_link"
            echo "Found image: $image_url" >&2
        fi
    done
    
    # Prepare JSON response
    if [ -n "$video_url" ]; then
        result="{\"status\": true, \"thumb\": \"$thumb\", \"video\": \"$video_url\", \"image\": null}"
    elif [ -n "$image_url" ]; then
        result="{\"status\": true, \"thumb\": \"$thumb\", \"video\": null, \"image\": \"$image_url\"}"
    else
        result="{\"status\": false, \"message\": \"No download links found\"}"
    fi
    
    echo "$result"
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <pinterest_url>"
    echo "Example: $0 'https://pin.it/2POBGlFJn'"
    exit 1
fi

pinterest_url="$1"
result=$(snappin_download "$pinterest_url")
echo "$result"
EOF
