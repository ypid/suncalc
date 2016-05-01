{
    name: .[0].name,
    url: .[0].url,
    license: .[0].license_short,
    tags: (.[1].keywords + [ "cross" ] | sort),
    description: .[0].description,
    version: .[0].version,
    releasenote: .[0].releasenote,
    contributors: ([ .[0].authors | sort_by(.name) | .[] | select(contains({ targets: [ "haxe" ]})).nick ] ),
    dependencies: .[0].dependencies.haxe,
}
