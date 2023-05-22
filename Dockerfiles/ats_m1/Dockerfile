# Base image.
FROM arm64v8/rockylinux:8

# ARG stuff for the build.
ARG username
ARG userid
ARG git_username
ARG git_email

# Back to base image.
RUN yum -y install epel-release dnf-plugins-core; yum config-manager --set-enabled powertools; yum repolist; \

    yum -y update; \
    # Compilers
    yum -y install ccache make pkgconfig bison flex gcc-c++ clang \
    # Autoconf
    autoconf automake libtool \
    # Various other tools
    sudo git rpm-build distcc-server file wget openssl hwloc nghttp2 libnghttp2-devel; \
    # Devel packages that ATS needs
    yum -y install openssl-devel expat-devel pcre-devel libcap-devel hwloc-devel libunwind-devel \
    xz-devel libcurl-devel ncurses-devel jemalloc-devel GeoIP-devel luajit-devel brotli-devel \
    ImageMagick-devel ImageMagick-c++-devel hiredis-devel zlib-devel libmaxminddb-devel \
    perl-ExtUtils-MakeMaker perl-Digest-SHA perl-URI curl tcl-devel java; \
    # autest stuff
    yum -y install python3 httpd-tools procps-ng nmap-ncat python3-pip \
    python3-gunicorn python3-requests python3-devel python3-psutil telnet;

RUN pip3 install --upgrade pip
RUN pip3 install pipenv httpbin
RUN yum -y install gcc-toolset-11 gcc-toolset-11-libasan-devel

# We put our custom packages in /opt.
RUN echo 'PATH=/opt/bin:$PATH' | tee -a /etc/profile.d/opt_bin.sh
ARG PATH=/opt/bin:$PATH

# Install a recent cmake.
RUN yum remove -y cmake
RUN \
  wget https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-linux-aarch64.sh; \
  chmod +x cmake-3.26.3-linux-aarch64.sh; \
  bash ./cmake-3.26.3-linux-aarch64.sh --skip-license --prefix=/opt

# Install openssl-quic
RUN yum install -y python38-devel cargo

RUN alternatives --set python /usr/bin/python3.8
RUN yum -y install libev-devel jemalloc-devel libxml2-devel \
    c-ares-devel libevent-devel jansson-devel zlib-devel systemd-devel

# go and rust will be installed by build_h3_tools.
RUN yum remove -y golang rust
ARG h3_tools_dir=/root/build_h3_tools
RUN mkdir -p ${h3_tools_dir}
WORKDIR ${h3_tools_dir}
COPY /build_h3_tools.sh ${h3_tools_dir}/build_h3_tools.sh
# This will install OpenSSL QUIC and related tools in /opt.
RUN bash ${h3_tools_dir}/build_h3_tools.sh
WORKDIR /root

# Install some of our needed go applications.
RUN echo 'export PATH=$PATH:/opt/go/bin' | tee -a /etc/profile.d/go.sh
RUN echo 'export GOBIN=/opt/go/bin' | tee -a /etc/profile.d/go.sh
RUN \
  /opt/go/bin/go install github.com/summerwind/h2spec/cmd/h2spec@latest; \
  cp /root/go/bin/h2spec /opt/go/bin/

RUN \
  /opt/go/bin/go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@v2.6.0; \
  cp /root/go/bin/go-httpbin /opt/go/bin/

RUN update-crypto-policies --set LEGACY

# Add the CI's test user. N.B: 1200 is the uid that our jenkins user is
# configured with, so that has to be used. Otherwise there will be permissions
# issues.
ARG jenkins_username=jenkins
ARG jenkins_uid=1200
RUN useradd \
    --home-dir /home/${jenkins_username} \
    --groups users,wheel \
    --uid ${jenkins_uid} \
    --shell /bin/bash \
    --create-home \
    ${jenkins_username}
RUN echo "${jenkins_username} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R ${jenkins_username} /home/${jenkins_username}

# Install lcov requirements.
RUN yum install -y perl-IO-Compress
ARG lcov_build_dir=/var/tmp/lcov_build_dir
RUN mkdir -p ${lcov_build_dir}
WORKDIR ${lcov_build_dir}
RUN git clone https://github.com/linux-test-project/lcov.git; \
    cd lcov; \
    # v1.15 is required for g++ version 9 compiled files.
    git checkout v1.15; \
    make install
WORKDIR /root
RUN rm -rf ${lcov_build_dir}

# Install ABI checking tools.
RUN yum install -y ctags elfutils-libelf-devel wdiff
COPY /install_abi_tools.sh /root/install_abi_tools.sh
RUN bash /root/install_abi_tools.sh

#------------------
# My customization.
#------------------
RUN yum install -y glibc-locale-source glibc-langpack-en
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# User-specific specifications.
RUN yum install -y the_silver_searcher tmux man-pages cmake

# The packaged version of neovim is old. Install a recent one.  This would be
# easier if fuse worked better in a docker build, but there doesn't seem to be
# an easy way to grant privileged access to a docker build run. So we have to
# do things by hand.
RUN git clone https://github.com/neovim/neovim; \
    cd neovim; \
    git checkout v0.7.0; \
    make -j `nproc`; \
    make install

# Install Bear. This takes a while, but I had trouble using an rpm.
RUN yum install -y json-devel spdlog-devel fmt-devel
RUN git clone https://github.com/rizsotto/Bear.git; \
    cd Bear/; \
    source /opt/rh/gcc-toolset-11/enable; \
    cmake -DENABLE_UNIT_TESTS=OFF -DENABLE_FUNC_TESTS=OFF; \
    make -j `nproc` all; \
    make install

# Python linting tools.
RUN pip install --upgrade pep257 mypy yapf autopep8 flake8 pylint pydocstyle pycodestyle

# Install nodejs for coc-vim.
RUN curl -o /tmp/lts -sL install-node.vercel.app/lts && bash /tmp/lts --yes

RUN useradd \
    --home-dir /home/$username \
    --gid users \
    --uid $userid \
    --shell /bin/bash \
    --create-home \
    $username
RUN echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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
RUN \
    sudo chown $username:nobody /home/$username/bin/*; \
    chmod 755 /home/$username/bin/*

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
RUN \
  sudo dnf clean metadata; \
  sudo dnf install -y clang clang-tools-extra

RUN  \
  git config --global user.name "$git_username"; \
  git config --global user.email $git_email

RUN echo "source /opt/rh/gcc-toolset-11/enable" >> /home/$username/.bashrc

# Update git to a more recent version. This, among probably other advantages,
# supports nvimdiff.
RUN \
  sudo yum install -y asciidoc xmlto libcurl-devel; \
  mkdir -p /home/${username}/src; \
  cd /home/${username}/src; \
  git clone https://github.com/git/git.git; \
  cd git/; \
  git checkout v2.34.1; \
  make configure; \
  ./configure --prefix=/usr/local; \
  make -j `nproc` all doc; \
  sudo yum -y remove git; \
  sudo yum -y remove 'git-*'; \
  sudo make install install-doc install-html; \
  cp contrib/completion/git-completion.bash /home/${username}/.git-completion.bash

# Use a recent fish and oh-my-zsh.
RUN sudo yum install -y zsh util-linux-user
RUN sh -c "`wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -`"
RUN \
   git clone https://github.com/zsh-users/zsh-autosuggestions /home/${username}/.oh-my-zsh/custom/plugins/zsh-autosuggestions; \
   git clone https://github.com/zsh-users/zsh-history-substring-search /home/${username}/.oh-my-zsh/custom/plugins/zsh-history-substring-search; \
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${username}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

COPY .zshrc /home/$username/
COPY aliases.zsh /home/$username/.oh-my-zsh/custom/aliases.zsh
COPY bneradt.zsh-theme /home/$username/.oh-my-zsh/custom/themes/bneradt.zsh-theme
RUN \
    sudo chown -R $username:nobody \
        .zshrc \
        .oh-my-zsh/

RUN echo "source /opt/rh/gcc-toolset-11/enable" >> /home/$username/.zshrc
RUN sudo chsh -s /usr/bin/zsh ${username}

# Install fzf
RUN \
  mkdir -p /home/${username}/src; \
  cd /home/${username}/src; \
  git clone https://github.com/junegunn/fzf.git; \
  cd fzf; \
  ./install --all

WORKDIR /home/$username

# Keep this at the end to clean up the yum cache.
RUN sudo yum clean all
