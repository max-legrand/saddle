dune build;

# If the file already exists, remove it
if [ -f ~/bin/saddle ]; then
    rm -f ~/bin/saddle
fi
cp -r _build/default/bin/main.exe ~/bin/saddle;
