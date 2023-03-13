#!/bin/sh

## === Configuration ===
url="https://khaled.github.io/"
blogindex="index.html"
dir="/home/laith/code/repos/khaled.github.io"
# Don't play with those
tmpdir=$(mktemp -d)
extractyaml() { grep "^${1}: " $2 | sed -e "s/^$1: //" ;}

new() {
	filename=$(echo "$1" | awk -F '[^[:alnum:]]+' -v OFS=- '{$0=tolower($0); $1=$1; gsub(/^-|-$/, "")} 1')
	printf  "\\n---\\ntitle: $1\\nauthor: $author\\ndate: $(date '+%a, %b %Y')\\ndec:\\ntags:\\n---" > $dir/articles/drafts/$filename.md
	$EDITOR $dir/articles/drafts/$filename.md ;}

list() {
	case "$(ls $1 | wc -l)" in

		0) echo "There's nothing to $2." && exit 1 ;;
		*) ls -rc $1 | awk -F '/' '{print $NF}' | nl
                read -rp "Pick an entry by number to $2, or press Ctrl-C to cancel. " number ;;
	esac
	chosen="$(ls -rc $1 | nl | grep -w " $number" | awk '{print $2}')"
	filename="$(basename "$chosen")" && filename="${filename%.*}" ;}
	

publish() {
	# Make the HTML page:
	title=$(extractyaml "title" $dir/articles/drafts/$filename.md)
	date=$(extractyaml "date" $dir/articles/drafts/$filename.md)
	author=$(extractyaml "author" $dir/articles/drafts/$filename.md)
#	tag=$(extractyaml "tag" $dir/articles/drafts/$filename.md)
	sed -i /---/,/---/d $dir/articles/drafts/$filename.md
	content=$(smu $dir/articles/drafts/$filename.md)
	# add index entry to blogindex and tag page:
	printf "<!DOCTYPE html>\\n<html lang=\"en\">\\n<head>\\n<title>Khaled's Webpage | $title</title>\\n<meta name="viewport" content='width=device-width, initial-scale=1'>\\n<link rel='stylesheet' type='text/css' href='../style.css'>\\n<style>\\n@font-face {font-family: Amiri;src: local(Amiri), url('../fonts/Amiri.woff2')}\\nbody {direction: rtl}\\n</style>\\n<meta charset='utf-8'/>\\n</head>\\n<body>\\n<div id="date">$date</div>\\n<div id=title>$title</div>\\n<hr style=margin:4rem>\\n${content}\\n<hr>\\n<footer>- <strong><a href='${url}'>${author}</a></strong></footer>\\n\\n</body>\\n</html>" > $dir/articles/${filename}.html
	printf "<a href=articles/${filename}.html>$title</a>\\n<div class='date'>Published on $date</div>\\n" > "$tmpdir/index"
	sed -i "/<!-- Index -->/r $tmpdir/index" "$dir/index.html"
#	sed -i "/<!-- Index -->/r $tmpdir/index" "$dir/tags/$tag.html"
	# Make an RSS item:
	rssdate="$(LC_TIME=ar_IQ date '+%a, %d %b %Y %H:%M:%S %z')"
	printf "\\n<item>\\n<title>$title</title>\\n<link href='articles/$filename.html'/>\\n<pubDate>${rssdate}</pubDate>\\n<author>${author}</author>\\n<guid></guid>\\n<description>${content}</description>\\n</item>\\n\\n" > "$tmpdir/rss"
	sed -i "/<!-- Index -->/r $tmpdir/rss" "$dir/rss.xml" ;}


case $1 in 
	n) new $2 ;; 
	p) list $dir/articles/drafts/ publish && publish ;;
	*) usage
esac
