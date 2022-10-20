# Super Duper Fantastic

This is the "bones" file, which generates the "meat" to be seen by everyone.

## Setting up

If you're using Windows, you can run Jekyll using the Linux Subsystem. Instructions here: http://daverupert.com/2016/04/jekyll-on-windows-with-bash/

On Mac you just need git and vscode.

NOTE: The update about a missing watch file is now resolved.

### Install Ruby

On Windows (Linux Subsystem):
```bash
$ sudo -s
$ apt update
$ apt install make gcc

$ apt-add-repository ppa:brightbox/ruby-ng
$ apt update
$ apt install ruby2.4 ruby2.4-dev ruby-switch
```

You can substitute ruby2.4 for whatever the latest version is.

You should be able to verify ruby is installed by running
```bash
$ ruby -v
```

Now you can add the version to ruby-switch:
```bash
$ ruby-switch --set ruby2.4
```

### Installing Jekyll

You'll have to install jekyll as a Ruby gem and the plugins we're using
```
$ gem install jekyll jekyll-paginate jekyll-archives
```

## Running the blog

You can run the blog by running the command:
```bash
$ jekyll serve -w
```

Now you can view the site at http://localhost:4000/

## Creating new posts

In the `_posts` folder, create a new file that follows the format `YEAR-MONTH-DAY-title.MARKUP`. Posts you write should be in Markdown, and an example filename would be `2016-12-31-new-years-eve-is-awesome.md`.

Markdown Reference: https://daringfireball.net/projects/markdown/basics

## Deploying to your site

Once you want to publish a new post, first you'll want to commit the changes you've made to this "bones" repository.

```bash
$ git add --all
$ git commit -m "Added my new year's post"
$ git push origin master
```

Now you can publish the new post by simply running:
```bash
$ rake
```


### Handling errors

If during `rake`, you see an error, you'll want to make sure you've cleaned your branch. Type the following:

```bash
$ git branch
```

If you see `gh-pages` as the current branch, type the following:

```bash
$ git reset --hard HEAD~1
$ git checkout master
```

Now you'll be back on the master branch. To ensure everything is correct, type:

```bash
$ git status
```

You should see a `Nothing to commit` message.
