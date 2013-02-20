define git::pull($localtree = '/srv/git/', $real_name = false,
            $reset = true, $clean = true, $branch = false,
            $git_tag = false, $user = '') {

    if $real_name {
        $_name = $real_name
    }
    else {
        $_name = $name
    }

    #
    # This resource enables one to update a working directory
    # from an upstream GIT source repository. Note that by default,
    # the working directory is reset (undo any changes to tracked
    # files), and clean (remove untracked files)
    #
    # Note that to prevent a reset to be executed, you can set $reset to
    # false when calling this resource.
    #
    # Note that to prevent a clean to be executed as part of the reset, you
    # can set $clean to false
    #

    if $reset {
        git::reset { $name:
            localtree => $localtree,
            real_name => $real_name,
            clean     => $clean,
            user      => $user
        }
    }

    if $git_tag {

        if $git_tag == 'latest' {
            $git_checkout_tag = '`git describe --tags $(git rev-list --tags --max-count=1)`'
        } else {
            $git_checkout_tag = $git_tag
        }

        @exec { "git_pull_exec_$name":
            cwd     => "$localtree/$_name",
            command => "sudo -u $user git fetch --tags",
            onlyif  => "test -d $localtree/$_name/.git/info"
        }

        exec { "git_checkout_tag_${name}_${git_tag}":
            cwd     => "$localtree/$_name",
            command => "sudo -u $user git checkout $git_checkout_tag",
            creates => "$localtree/$_name/git/refs/tags/$git_checkout_tag",
        }
    } else {

        if $user == '' {
          @exec { "git_pull_exec_$name":
              cwd     => "$localtree/$_name",
              command => 'git pull',
              onlyif  => "test -d $localtree/$_name/.git/info"
          }
        }
        else {
          @exec { "git_pull_exec_$name":
              cwd     => "$localtree/$_name",
              command => "sudo -u $user git pull",
              onlyif  => "test -d $localtree/$_name/.git/info"
          }
        }

        case $branch {
            false: {}
            default: {
                exec { "git_pull_checkout_${branch}_${localtree}/${name}":
                    cwd     => "$localtree/$_name",
                    command => "git checkout --track -b $branch origin/$branch",
                    creates => "$localtree/$_name/.git/refs/heads/$branch"
                }
            }
        }
    }

    if defined(Git::Reset[$name]) {
        Exec["git_pull_exec_$name"] {
            require +> Git::Reset[$name]
        }
    }

    if defined(Git::Clean[$name]) {
        Exec["git_pull_exec_$name"] {
            require +> Git::Clean[$name]
        }
    }

    realize(Exec["git_pull_exec_$name"])
}
