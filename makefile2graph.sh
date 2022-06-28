remake --profile
gprof2dot --format=callgrind --output=mg.dot -n 0 -e 0 -w -s $(ls -t ./callgrind.out.* | head -1)
rm ./callgrind.out.*
declare -a arr=("!/Britain_TilePopulation\/raw\//") # exclude patterns from graph
for i in "${arr[@]}"
do
   awk "$i" mg.dot > mgprune.dot
   mv mgprune.dot mg.dot
done
sed -i '' "s#$(pwd)/##g" mg.dot # truncate file names by removing $(pwd)
dot -Tpng mg.dot -o ./output/makefilegraph.png
rm mg.dot
