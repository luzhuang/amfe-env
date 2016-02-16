#!/bin/sh

# variables
basedir=`dirname "$0"`
workdir=`dirname "$basedir"`
tpldir="$workdir/sitetpl"
tplurl="git@gitlab.alibaba-inc.com:mtb/tpl-website.git"
sitedir="$workdir/site"
docdir="$workdir/doc"
samplesdir="$workdir/samples"
packbin="$basedir/readpack.js"
renderbin="$basedir/tplrender.js"
repourl=`$packbin repository.url`

# functions
update(){
    echo "update website template"

    # clear website dir
    echo "clear $tpldir"
    if [ -d "$tpldir" ]; then
        rm -rf "$tpldir"
    fi

    echo "create $tpldir"
    mkdir "$tpldir"

    # update website repo
    echo "entering $tpldir & update git repo"
    cd $tpldir
    git init
    git remote add origin $tplurl
    git pull origin github
    rm -rf .git
    cd ..
}

clear(){
    # clear dirs
    if [ -d "$sitedir" ]; then
        rm -rf "$sitedir"
    fi

    echo "create $sitedir"
    mkdir "$sitedir"

    if ! [ -d "$docdir" ]; then
        echo "create $docdir"
        mkdir "$docdir"
    fi
}

build(){
    echo "build website template"

    # generate gitbook
    echo "generate gitbook"

    gitbook build "$docdir" "$sitedir/book"

    # copy samples
    echo "copy $samplesdir"
    cp -r $samplesdir "$sitedir"

    # generate sitetpl

    # check if tpldir is empty
    if ! [ -d "$tpldir" ]; then
        update
    fi

    echo "compy site template"
    cp -r "$tpldir"/* "$sitedir"

    echo "render template"
    $renderbin $sitedir/index.tpl > $sitedir/index.html
    rm $sitedir/index.tpl
}

serve() {
    if [ -f "$workdir/server.log" ]; then
        echo "clear server log"
        rm -f "server.log"
    fi

    if [ -f "$workdir/server.pid" ]; then
        echo "stop server"
        cat "$workdir/server.pid" | xargs kill -9
    fi

    echo "start server"
    echo "serving $sitedir on port 4000"
    nohup serve "$sitedir" -p 4000 > "$workdir/server.log" &
    echo $! > "$workdir/server.pid"
}

publish(){
    echo "publish website"

    # clear everythings
    clear

    # init git repo
    echo "entering $sitedir & init git repo"
    cd $sitedir
    git init
    git remote add origin $repourl
    git pull --all
    git checkout -b gh-pages

    checkPages=`git branch -r | grep gh-pages`

    if [ x"origin/gh-pages" == x"$checkPages" ]; then
        git pull origin gh-pages
    fi

    echo "leaving $sitedir"
    cd ..

    # build website
    build

    # commit
    echo "entering $sitedir & git commit & push"
    cd $sitedir
    git add -A
    git commit -m "Publish site"
    git push origin gh-pages --force
    echo "leaving $sitedir"
    cd ..
}

# switch command
command="$1"

if [ x"update" == x"$command" ]; then
    update
fi

if [ x"build" == x"$command" ]; then
    clear
    build
fi

if [ x"serve" == x"$command" ]; then
    serve
fi

if [ x"publish" == x"$command" ]; then
    publish
fi