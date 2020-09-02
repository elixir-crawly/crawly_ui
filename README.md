# CrawlyUI

[![Build Status](https://travis-ci.org/oltarasenko/crawly_ui.svg?branch=master)](https://travis-ci.org/github/oltarasenko/crawly_ui)
[![Coverage Status](https://coveralls.io/repos/github/oltarasenko/crawly_ui/badge.svg?branch=master)](https://coveralls.io/github/oltarasenko/crawly_ui?branch=master)

## Motivation for the project

Web scraping is simple. You can easily fetch many pages with CURL or any other
old good client. However we don't believe it :)!

We thing that web scraping is complex if you do it commercially.
Most of the times we see that, indeed people can extract pages with simple curl
based client (or Floki + something), however they normally fail if it comes about
clear deliverable.

We think that Crawling is hard when it comes to:
1. Scalability - imagine you have SLA to deliver another million of items before the EOD
2. Data quality - it's easy to get some pages, it's hard to extract the right data
3. Javascript - most of the platforms would not even mention it :)
4. Coverage - what if you need to get literally all pages/products, do you really
   plan to check it all manually using the command line?

## Our approach

We have created a platform which allows to manage jobs and to visualize items in the
nice way. We believe it's important to see how your data looks! It's important to
be able to filter it, analyzing every job and comparing jobs.

And finally it's important to be able to compare extracted data with the data on
the target website.

We think that web scraping is a process! It involves development, debugging, QA
and finally maintenance. And that's what we're trying to achieve with CrawlyUI
project.

## Trying it
You could run it locally using the following commands

1. `docker-compose build`
2. `docker-compose up -d postgres`
3. `docker-compose run ui bash -c "/crawlyui/bin/ec eval \"CrawlyUI.ReleaseTasks.migrate\""`
4. `docker-compose up ui worker`

This should bring the Crawly UI, Crawly worker (with Crawly Jobs in example folder)
and postgres database for you. Now you can access the server from localhost:80

## Gallery

1. Main page. Schedule jobs here!
![Main Page](gallery/main_page.png?raw=true)

2. Items browser
![Items browser](gallery/items_page.png?raw=true)
![Items browser search](gallery/item_with_filters.png?raw=true)

3. Items preview
![Items browser](gallery/item_preview_example.png?raw=true)

## How it works

CrawlyUI is a phoenix application, which is responsible for working with Crawly
nodes. All nodes are connected to CrawlyUI using the erlang distribution. CrawlyUI
can operate as many nodes as you want (or as many as erlang distribution can handle ~100)

# Testing it locally (with your own Crawly jobs)

## Your own Crawly Implementation

### Configure your Crawly

1. Add SendToUI pipeline to the list of your item pipelines (before encoder pipelines)
`{Crawly.Pipelines.Experimental.SendToUI, ui_node: :<crawlyui-node-name>}`, example:

``` elixir
config :crawly,
  pipelines: [
     {Crawly.Pipelines.Validate, fields: [:id]},
     {Crawly.Pipelines.DuplicatesFilter, item_id: :id},
     {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui@127.0.0.1},
     Crawly.Pipelines.JSONEncoder,
     {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "jl"}
  ]
```

2. Organize erlang cluster so Crawly nodes can find CrawlyUI node, in this case we use
[erlang-node-discovery](https://github.com/oltarasenko/erlang-node-discovery) application for this task,
however any other alternative would also work. For setting up erlang-node-discovery:

- add the following code dependency to deps section of mix.exs
`{:erlang_node_discovery, git: "https://github.com/oltarasenko/erlang-node-discovery"}`
- add the following lines to the config.exs:

``` elixir
config :erlang_node_discovery,
hosts: ["127.0.0.1", "crawlyui.com"], node_ports: [{:ui, 4000}]
```

### Start your Crawly node
Start an iex session in your Crawly implementation directory with `--cookie`
(which should be same with your CrawlyUI session), you can also define a node name with option `--name`
and it will be your Crawly node name that shows up on the UI, example:

``` bash
$ iex --name worker@worker.com --cookie 123 -S mix
```

## CrawlyUI

### Start the database

Start postgres with the command

``` bash
$ docker-compose build
$ docker-compose up -d postgres
```

### Start CrawlyUI session

Start an iex session in CrawlyUI directory with `--name <crawlyui-node-name>`
and `--cookie` that is the same with the crawly session, example:

``` bash
$ iex --name ui@127.0.0.1 --cookie 123 -S mix phx.server
```

The interface will be available on [localhost:4000]() for your tests.

# Item previews

If your item has URL field you will get a nice preview capabilities, with the
help of iframe.

NOTE:

Iframes are blocked almost by every large website. However you can easily overcome it by
using Ignore X-Frame headers browser extension.

# Roadmap

- [ ] Make tests to have 80% tests coverage
- [ ] Get logs from Crawly
- [ ] Allow to stop given spiders
- [ ] Parametrize spider parameters
- [ ] Export items (CSV, JSON)
- [ ] Make better search (search query language like in Kibana)
- [ ] UI based spider generation