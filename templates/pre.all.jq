"/*
 * @name: " + .[0].name + "
 * @description: " + .[0].description + "
 * @source: " + .[0].target_info.haxe.source_file + "
 * @license: " + .[0].license.name.spdx_identifier + "
" +
    ( [ .[0].authors | sort_by(.name)
        | .[] | select(contains({ targets: [ "haxe" ]}) or contains({ targets: [ "role::upstream" ]}))
        | (" * @author: " + .name + (if has("email") then (" <" + .email + ">") else "" end)) ]
        | join("\n") ) + "
 */"
