#! /bin/bash

# Reset marker for optind
OPTIND=1

# Set our own variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define a function to show help text
function show_help {
  echo "Usage:"
  echo "   make_ip2sg_package [-f] file_name"
  exit 1
}

# Define a function to show debug info
function debug_info {
  echo ""
  echo ""
  echo "Showing debugging information..."
  echo ""
  tree -a "$PACKAGE_DIR"
  echo ""
  echo "Variable values:"
  echo '$FILE_DIR' "is $FILE_DIR"
  echo '$FILE_NAME' "is $FILE_NAME"
  echo '$FILE_NAME_NO_SUFFIX' "is $FILE_NAME_NO_SUFFIX"
  echo '$FILE_MD5' "is $FILE_MD5"
  echo '$PACKAGE_DIR' "is $PACKAGE_DIR"
  echo '$PACKAGE_NAME' "is $PACKAGE_NAME"
  echo '$ZIP_FILE_PATH' "is $ZIP_FILE_PATH"
  echo '$UUID' "is $UUID"
  echo '$XML_DIR' "is $XML_DIR"
  echo '$RELS_DIR' "is $RELS_DIR"
  echo '$RELS_FILE' "is $RELS_FILE"
  echo ""
  echo "Contents of content types file:"
  cat "$PACKAGE_DIR/[Content_Types].xml"
  echo ""
  echo "Contents of .rels file:"
  cat "$RELS_FILE"
  echo ""
  echo "Contents of .frmx zip file:"
  unzip -l ../$PACKAGE_NAME.frmx
  echo ""
  exit 1
}

while getopts ":h:" OPT; do
    case "$OPT" in
    h)  show_help
        ;;
    *)  show_help
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# Store the operand as the name of the application
FILE_PATH=$@

if [[ ! -f $FILE_PATH ]]; then
  echo "File $FILE_PATH does not exist. Quitting."
  exit 1
fi

FILE_DIR="$(dirname "$FILE_PATH")"
FILE_NAME="$(basename "$FILE_PATH")"
FILE_NAME_NO_SUFFIX="$(basename "$FILE_PATH" .xml)"
FILE_MD5="$(openssl md5 "$FILE_PATH" | awk '{ print $NF }')"
PACKAGE_DIR="$FILE_DIR/$FILE_NAME_NO_SUFFIX"
PACKAGE_NAME="$FILE_NAME_NO_SUFFIX"
ZIP_FILE_PATH="$FILE_DIR/$PACKAGE_NAME.frmx"
UUID="$(uuidgen)"
XML_DIR="$PACKAGE_DIR/$UUID"
RELS_DIR="$PACKAGE_DIR/_rels"
RELS_FILE="$RELS_DIR/.rels"

if [[ -d "$PACKAGE_DIR" ]]; then
  read -p "Delete existing package directory $PACKAGE_DIR (Y/n)? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Package directory $PACKAGE_DIR already present. Quitting."
    exit 1
  else
    echo "Deleting directory $PACKAGE_DIR..."
    rm -Rf "$PACKAGE_DIR"
  fi
fi

echo "Creating new directory for package $PACKAGE_DIR..."
mkdir -p "$PACKAGE_DIR"

echo "Creating [Content_Types].xml file to specify content types..."
cp -f "$SCRIPT_DIR/templates/content_types.xml" "$PACKAGE_DIR/[Content_Types].xml"

echo "Creating directory for XML file..."
mkdir -p "$XML_DIR"

echo "Copying XML file into XML directory..."
cp -f "$FILE_PATH" "$XML_DIR/"

echo "Creating _rels directory to store relationships..."
mkdir -p "$RELS_DIR"

echo "Creating .rels file to specify relationships..."
cp -f "$SCRIPT_DIR/templates/rels.xml" "$RELS_FILE"

RELATIONSHIP="<Relationship Type=\"http://schemas.openxmlformats.org/ip2sg/package/relationships/efilingapplication\" Target=\"/$UUID/$FILE_NAME\" Id=\"$FILE_MD5\" />"

echo "Adding relationship to .rels file..."
sed -i '' '/<\/Relationships>/i \
'"$RELATIONSHIP"'
' "$RELS_FILE"

if [[ -f "$PACKAGE_DIR/.DS_Store" ]]; then
  echo "Removing .DS_Store file..."
  rm "$PACKAGE_DIR/.DS_Store"
fi

if [[ -f "$ZIP_FILE_PATH" ]]; then
  read -p "Delete existing zip file $PACKAGE_NAME.frmx (Y/n)? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Zip file $PACKAGE_NAME.frmx already present. Quitting."
    exit 1
  else
    echo "Deleting file $PACKAGE_NAME.frmx..."
    rm -Rf "$ZIP_FILE_PATH"
  fi
fi

echo "Making the zip file..."
cd "$PACKAGE_DIR" && zip -r "$ZIP_FILE_PATH" "$PACKAGE_DIR"

debug_info
