{
    ## https://getcomposer.org/doc/04-schema.md
    name: ("ypid/" + .[0].name),
    type: "library",
    description: .[0].description,
    keywords: (.[1].keywords | sort),
    homepage: .[0].url,
    support: .[0].support,
    license: .[0].license.name.spdx_identifier,
    authors: ([ .[0].authors | sort_by(.name) | .[] | select(contains({ targets: [ "php" ]}) or contains({ targets: [ "role::upstream" ]})) ] ),
    # "autoload": {
    #     "psr-0" : {
    #         "SunCalc" : "lib"
    #     }
    # }
}
