# Base image.
FROM arm64v8/fedora:38

# ARG stuff for the build.
ARG username
ARG userid
ARG git_username
ARG git_email

#-------------------------------------------------------------------------------
# Install the various system packages we use.
#-------------------------------------------------------------------------------
RUN <<EOF
  set -e

  yum -y install dnf-plugins-core
  yum repolist
  yum -y update

  # Build tools.
  yum -y install \
    ccache make pkgconfig bison flex gcc-c++ clang \
    autoconf automake libtool \
    cmake ninja-build

  # Various other tools
  yum -y install \
    sudo git rpm-build distcc-server file wget openssl hwloc \
    nghttp2 libnghttp2-devel

  # Devel packages that ATS needs
  yum -y install \
    openssl-devel expat-devel pcre-devel libcap-devel hwloc-devel libunwind-devel \
    xz-devel libcurl-devel ncurses-devel jemalloc-devel GeoIP-devel luajit-devel brotli-devel \
    ImageMagick-devel ImageMagick-c++-devel hiredis-devel zlib-devel libmaxminddb-devel \
    perl-ExtUtils-MakeMaker perl-Digest-SHA perl-URI curl tcl-devel java

  # autest stuff
  yum -y install \
    python3 httpd-tools procps-ng nmap-ncat python3-pip \
    python3-gunicorn python3-requests python3-devel python3-psutil telnet
EOF

#-------------------------------------------------------------------------------
# Install some custom build tools.
#-------------------------------------------------------------------------------

WORKDIR /root

# We put our custom packages in /opt.
RUN <<EOS
  set -e
  mkdir -p /opt/bin
  chmod 755 /opt/bin
  echo 'PATH=/opt/bin:$PATH' | tee -a /etc/profile.d/opt_bin.sh
EOS
ARG PATH=/opt/bin:$PATH

# This currently fails with latest fedora:38. Presumably the stock pip is
# recent enough, so this shouldn't be a big deal.
# RUN pip3 install --upgrade pip
RUN pip3 install pipenv httpbin

#-------------------------------------------------------------------------------
# Install the HTTP/3 build tools, including openssl-quic.
#-------------------------------------------------------------------------------
RUN yum -y install libev-devel jemalloc-devel libxml2-devel \
    c-ares-devel libevent-devel jansson-devel zlib-devel systemd-devel \
    perl-FindBin cargo

# go will be installed by build_h3_tools.
RUN yum remove -y golang
ARG h3_tools_dir=/root/build_h3_tools
RUN mkdir -p ${h3_tools_dir}
COPY /build_h3_tools.sh ${h3_tools_dir}/build_h3_tools.sh
# This will install OpenSSL QUIC and related tools in /opt.
RUN <<EOS
  set -e
  cd ${h3_tools_dir}
  bash ${h3_tools_dir}/build_h3_tools.sh
  rm -rf ${h3_tools_dir} /root/.rustup
EOS

#-------------------------------------------------------------------------------
# Various CI Job and Test Requirements.
#-------------------------------------------------------------------------------

# Autests require some go applications.
RUN <<EOS
  set -e
  echo 'export PATH=$PATH:/opt/go/bin' | tee -a /etc/profile.d/go.sh
  echo 'export GOBIN=/opt/go/bin' | tee -a /etc/profile.d/go.sh

  /opt/go/bin/go install github.com/summerwind/h2spec/cmd/h2spec@latest
  cp /root/go/bin/h2spec /opt/go/bin/

  /opt/go/bin/go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@v2.6.0
  cp /root/go/bin/go-httpbin /opt/go/bin/
EOS

# Add the CI's test user. N.B: 1200 is the uid that our jenkins user is
# configured with, so that has to be used. Otherwise there will be permissions
# issues.
ARG jenkins_username=jenkins
ARG uid=1200
RUN <<EOS
  set -e
  useradd \
    --home-dir /home/${jenkins_username} \
    --groups users,wheel \
    --uid ${uid} \
    --shell /bin/bash \
    --create-home \
    ${jenkins_username}
  echo "${jenkins_username} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
  chown -R ${jenkins_username} /home/${jenkins_username}
EOS

# Install lcov
RUN yum install -y lcov


#------------------
# My customization.
#------------------
RUN yum install -y glibc-locale-source glibc-langpack-en
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# User-specific specifications.
RUN <<EOF
  yum install -y \
    ctags the_silver_searcher tmux man-pages neovim bear git tcpdump
EOF

# Python linting tools.
RUN pip install --upgrade pep257 mypy yapf autopep8 flake8 pylint pydocstyle pycodestyle

# Install nodejs for coc-vim.
RUN curl -o /tmp/lts -sL install-node.vercel.app/lts && bash /tmp/lts --yes

RUN <<EOS
  set -e
  useradd \
    --home-dir /home/$username \
    --gid users \
    --uid $userid \
    --shell /bin/bash \
    --create-home \
    $username
  echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOS

USER $username
WORKDIR /home/$username
RUN mkdir -p bin

COPY \
    /bisect_with_autest \
    /build_ats \
    /clean_build_test \
    /build_ats_core \
    /build_ats_coverage \
    /build_ats_not_quic \
    /build_ats_with_clang \
    /cos \
    /normalize_log \
    /start_ats_project \
    /pretty_print_json \
    /home/$username/bin/

# Alas, COPY is not run as USER, and older docker version do not have --chown
# for COPY.
RUN <<EOS
  set -e
  sudo chown $username:nobody /home/$username/bin/*
  chmod 755 /home/$username/bin/*
EOS

COPY \
    .agignore \
    .aliases \
    .bashrc \
    .editrc \
    .git-completion.bash \
    .git-prompt.sh \
    .gitconfig \
    .inputrc \
    .pylintrc \
    .tmux.conf \
    .tmux-completion.bash \
    .vimrc \
    /home/$username/

RUN mkdir .vim
COPY .vim .vim

RUN mkdir .git_template
COPY .git_template .git_template

RUN mkdir -p .config/nvim
COPY init.vim .config/nvim
COPY coc-settings.json .config/nvim

RUN \
    sudo chown -R $username:nobody \
        .agignore \
        .aliases \
        .bashrc \
        .config/ \
        .editrc \
        .git-completion.bash \
        .git-prompt.sh \
        .gitconfig \
        .git_template \
        .inputrc \
        .pylintrc \
        .tmux.conf \
        .tmux-completion.bash \
        .vim \
        .vimrc

# Use vim-plug to retrieve and install plugins from the vimrc.
RUN \
    curl -fLo .local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install the vim plugins.
RUN nvim +'PlugInstall --sync' +qa
RUN nvim +'CocInstall -sync coc-clangd coc-pyright coc-json coc-sh' +qall

# Install the latest version of clang.
RUN <<EOS
  set -e
  sudo dnf clean metadata
  sudo dnf install -y clang clang-tools-extra
EOS

RUN <<EOS
  set -e
  git config --global user.name "$git_username"
  git config --global user.email $git_email
EOS

# Use a recent fish and oh-my-zsh.
RUN sudo yum install -y zsh util-linux-user
RUN sh -c "`wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -`"
RUN <<EOS
   set -e
   git clone https://github.com/zsh-users/zsh-autosuggestions /home/${username}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-history-substring-search /home/${username}/.oh-my-zsh/custom/plugins/zsh-history-substring-search
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${username}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
EOS

COPY .zshrc /home/$username/
COPY aliases.zsh /home/$username/.oh-my-zsh/custom/aliases.zsh
COPY bneradt.zsh-theme /home/$username/.oh-my-zsh/custom/themes/bneradt.zsh-theme
RUN \
    sudo chown -R $username:nobody \
        .zshrc \
        .oh-my-zsh/

RUN sudo chsh -s /usr/bin/zsh ${username}

# Install fzf, which adds shell shortcuts.
RUN <<EOS
  set -e
  mkdir -p /home/${username}/src
  cd /home/${username}/src
  git clone https://github.com/junegunn/fzf.git
  cd fzf
  ./install --all
EOS

WORKDIR /home/$username

# Keep this at the end to clean up the yum cache.
RUN sudo yum clean all
