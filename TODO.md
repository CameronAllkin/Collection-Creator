# Design

## All Pages
- Fix layout issues
    - fix layout of some large unbound widgets
        - especially long expanded widgets in columns that take up a lot of space
    - fix button layout for better UX
- fix scroll issues
    - some devices have some weird scroll physics when going through some pages



# Functionality

## Collections
- Favourites
- Sync with firebase
    - User login and persistent data

## Collection
- Keep filtered columns on new items and schema changes
- options for adjustable column width in display 

## Schema
- formula for automatic filling of field 
    - e.g. formula given on schem creation, not filled in manually by user per item, generated on item creation
- editing, renaming, and reordering all in one interface not two

## Item
- clicking on image opens a fullscreen version of image
- clicking on link takes you to external website



# Data

## Data Types
- Link
- Formula

## Data Conversion
- Format changed schema data types in the data so that they are accurate to the type.
    - e.g. when changing a field from double to int, convert that fields value in all collection items from double to int.
- provide option to auto-convert on schema change

## Data Sharing
- Provide option to download/share collection 
    - currently collection is stored as a JSON-like box in local app storage
    - download as JSON
    - share link as JSON, maybe auto load into app storage of shared device

