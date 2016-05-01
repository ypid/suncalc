{
    name: ("ypid/" + .[0].name),
    type: "library",
    description: .[0].description,
    keywords: (.[1].keywords | sort),
    homepage: .[0].url,
    support: .[0].support,
    license: .[0].license_full,
    authors: ([ .[0].authors | sort_by(.name) | .[] | select(contains({ targets: [ "php" ]})) ] ),
    # "autoload": {
    #     "psr-0" : {
    #         "SunCalc" : "lib"
    #     }
    # }
}
