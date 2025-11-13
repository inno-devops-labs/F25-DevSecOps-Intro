#!/bin/bash

# Script to convert ZAP JSON report to XML format
# Usage: ./json_to_xml_converter.sh input.json output.xml

set -euo pipefail

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input.json> <output.xml>"
    echo "Example: $0 zap-report-noauth.json zap-report-noauth.xml"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Function to escape XML special characters
escape_xml() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Function to convert timestamp to readable format
convert_timestamp() {
    local timestamp="$1"
    if [[ "$timestamp" =~ ^[0-9]+$ ]] && [[ ${#timestamp} -eq 10 ]]; then
        date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S'
    else
        echo "$timestamp"
    fi
}

echo "Converting ZAP JSON report to XML format..."

# Start XML output
cat > "$OUTPUT_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
EOF

# Extract basic report information
PROGRAM_NAME=$(jq -r '.["@programName"] // "ZAP"' "$INPUT_FILE")
VERSION=$(jq -r '.["@version"] // "unknown"' "$INPUT_FILE")
GENERATED=$(jq -r '.["@generated"] // "unknown"' "$INPUT_FILE")
CREATED=$(jq -r '.created // "unknown"' "$INPUT_FILE")

# Add root element and header info
cat >> "$OUTPUT_FILE" << EOF
<ZAPReport version="$VERSION" generated="$GENERATED">
    <created>$CREATED</created>
EOF

# Process each site
jq -c '.site[]' "$INPUT_FILE" | while IFS= read -r site; do
    SITE_NAME=$(echo "$site" | jq -r '.["@name"]' | escape_xml)
    SITE_HOST=$(echo "$site" | jq -r '.["@host"]' | escape_xml)
    SITE_PORT=$(echo "$site" | jq -r '.["@port"]')
    SITE_SSL=$(echo "$site" | jq -r '.["@ssl"]')
    
    cat >> "$OUTPUT_FILE" << EOF
    <site name="$SITE_NAME" host="$SITE_HOST" port="$SITE_PORT" ssl="$SITE_SSL">
EOF
    
    # Process each alert for this site
    echo "$site" | jq -c '.alerts[]?' | while IFS= read -r alert; do
        PLUGIN_ID=$(echo "$alert" | jq -r '.pluginid')
        ALERT_REF=$(echo "$alert" | jq -r '.alertRef')
        ALERT_NAME=$(echo "$alert" | jq -r '.alert // .name' | escape_xml)
        RISK_CODE=$(echo "$alert" | jq -r '.riskcode')
        CONFIDENCE=$(echo "$alert" | jq -r '.confidence')
        RISK_DESC=$(echo "$alert" | jq -r '.riskdesc' | escape_xml)
        DESC=$(echo "$alert" | jq -r '.desc' | escape_xml)
        COUNT=$(echo "$alert" | jq -r '.count')
        SOLUTION=$(echo "$alert" | jq -r '.solution' | escape_xml)
        OTHER_INFO=$(echo "$alert" | jq -r '.otherinfo' | escape_xml)
        REFERENCE=$(echo "$alert" | jq -r '.reference' | escape_xml)
        CWE_ID=$(echo "$alert" | jq -r '.cweid')
        WASC_ID=$(echo "$alert" | jq -r '.wascid')
        SOURCE_ID=$(echo "$alert" | jq -r '.sourceid')
        
        cat >> "$OUTPUT_FILE" << EOF
        <alertitem>
            <pluginid>$PLUGIN_ID</pluginid>
            <alertRef>$ALERT_REF</alertRef>
            <alert>$ALERT_NAME</alert>
            <name>$ALERT_NAME</name>
            <riskcode>$RISK_CODE</riskcode>
            <confidence>$CONFIDENCE</confidence>
            <riskdesc>$RISK_DESC</riskdesc>
            <desc><![CDATA[$DESC]]></desc>
            <count>$COUNT</count>
            <solution><![CDATA[$SOLUTION]]></solution>
            <otherinfo><![CDATA[$OTHER_INFO]]></otherinfo>
            <reference><![CDATA[$REFERENCE]]></reference>
            <cweid>$CWE_ID</cweid>
            <wascid>$WASC_ID</wascid>
            <sourceid>$SOURCE_ID</sourceid>
            <instances>
EOF
        
        # Process each instance for this alert
        echo "$alert" | jq -c '.instances[]?' | while IFS= read -r instance; do
            INSTANCE_ID=$(echo "$instance" | jq -r '.id')
            URI=$(echo "$instance" | jq -r '.uri' | escape_xml)
            METHOD=$(echo "$instance" | jq -r '.method')
            PARAM=$(echo "$instance" | jq -r '.param' | escape_xml)
            ATTACK=$(echo "$instance" | jq -r '.attack' | escape_xml)
            EVIDENCE=$(echo "$instance" | jq -r '.evidence' | escape_xml)
            INSTANCE_OTHER_INFO=$(echo "$instance" | jq -r '.otherinfo' | escape_xml)
            
            cat >> "$OUTPUT_FILE" << EOF
                <instance>
                    <id>$INSTANCE_ID</id>
                    <uri>$URI</uri>
                    <method>$METHOD</method>
                    <param><![CDATA[$PARAM]]></param>
                    <attack><![CDATA[$ATTACK]]></attack>
                    <evidence><![CDATA[$EVIDENCE]]></evidence>
                    <otherinfo><![CDATA[$INSTANCE_OTHER_INFO]]></otherinfo>
                </instance>
EOF
        done
        
        cat >> "$OUTPUT_FILE" << EOF
            </instances>
        </alertitem>
EOF
    done
    
    cat >> "$OUTPUT_FILE" << EOF
    </site>
EOF
done

# Close root element
cat >> "$OUTPUT_FILE" << EOF
</ZAPReport>
EOF

echo "Conversion completed successfully!"
echo "XML output saved to: $OUTPUT_FILE"

# Validate XML if xmllint is available
if command -v xmllint &> /dev/null; then
    echo "Validating XML structure..."
    if xmllint --noout "$OUTPUT_FILE" 2>/dev/null; then
        echo "✓ XML is well-formed"
    else
        echo "⚠ Warning: XML validation failed"
    fi
fi

# Display basic statistics
TOTAL_ALERTS=$(jq '[.site[].alerts[]] | length' "$INPUT_FILE")
TOTAL_INSTANCES=$(jq '[.site[].alerts[].instances[]] | length' "$INPUT_FILE")

echo ""
echo "Report Statistics:"
echo "- Total Alerts: $TOTAL_ALERTS"
echo "- Total Instances: $TOTAL_INSTANCES"
echo "- Output file size: $(du -h "$OUTPUT_FILE" | cut -f1)"
