is_github_ci() = "CI" in keys(ENV)
"""
    is_sudo_env()

Check whether we need sudo.
This differs between GitHub and GitLab CI.
"""
function is_sudo_env()
    try 
        run(`sudo echo foo`)
        return true
    catch
        return false
    end
end
sudo_prefix() = is_sudo_env() ? "sudo" : ""
function nonempty_run(args::Vector)
    filter!(!=(""), args)
    run(`$args`)
end

function install_apt_packages()
    @assert is_github_ci()
    packages = [
        "make", 
        "pdf2svg", 
        "rsvg-convert",
        "texlive-fonts-recommended", 
        "texlive-fonts-extra",
        "texlive-latex-base",
        "texlive-binaries",
        "texlive-xetex",
        "xz-utils" # Required by tar.
    ]

    sudo = sudo_prefix()
    args = [sudo, "apt-get", "-qq", "update"]
    nonempty_run(args)
    for package in packages
        println("Installing $package via apt")
        args = [sudo, "apt-get", "install", "-y", package]
        nonempty_run(args)
    end
end

function install_via_tar()
    @assert is_github_ci()
    sudo = sudo_prefix()
    PANDOC_VERSION = "2.10.1"
    CROSSREF_VERSION = "0.3.8.1"

    filename = "pandoc-$PANDOC_VERSION-1-amd64.deb"
    download("https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/$filename", filename)
    args = [sudo, "dpkg", "-i", filename]
    nonempty_run(args)

    filename = "pandoc-crossref-Linux.tar.xz"
    download("https://github.com/lierdakil/pandoc-crossref/releases/download/v$CROSSREF_VERSION/$filename", filename)
    run(`tar -xf $filename`)
    name = "pandoc-crossref"
    target = joinpath(pwd(), "$name")
    source = "/usr/local/bin/$name"
    try
        run(`ln -s $target $source`)
    catch # In this case, GitHub needs sudo privileges.
        run(`sudo ln -s $target $source`)
    end
end

function install_dependencies()
    install_apt_packages()
    install_via_tar()
end
