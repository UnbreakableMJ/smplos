function compress --description 'Compress a file/directory to tar.gz'
    tar -czf (string replace -r '/$' '' -- $argv[1]).tar.gz (string replace -r '/$' '' -- $argv[1])
end
