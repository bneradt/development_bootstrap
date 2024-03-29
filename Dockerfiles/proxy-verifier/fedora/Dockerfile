FROM fedora:38

ARG username
ARG userid
ARG git_username
ARG git_email

# Packages for building Proxy Verifier and its dependencies.
RUN <<EOF
  set -e

  dnf install -y dnf-plugins-core
  dnf update -y
  dnf group install -y "Development Tools"

  dnf install -y \
    pipenv python3-devel python3-pip openssl-devel \
    cmake autoconf libtool pkg-config clang \
    glibc-static libstdc++-static \
    curl sudo git bzip2 \
    perl-ExtUtils-MakeMaker perl-Digest-SHA perl-URI perl-FindBin \
    perl-IPC-Cmd perl-Pod-Html
EOF

RUN <<EOF
  set -e
  cd /var/tmp
  git clone https://github.com/yahoo/proxy-verifier.git
  pushd proxy-verifier
  version=$(awk -F\" '/PartVersion/ {print $2}' local/parts/proxy-verifier.part)
  bash tools/build_library_dependencies.sh /opt/pv_libs_${version}
  popd
  rm -rf proxy-verifier
EOF

# User-specific specifications.
RUN <<EOF
  set -e
  dnf install -y \
    ctags the_silver_searcher tmux man-pages neovim bear tcpdump gdb \
    net-tools wget which clang-tools-extra
EOF

# Python linting tools.
RUN pip install --upgrade pep257 mypy yapf autopep8 flake8 pylint pydocstyle pycodestyle

# Install nodejs for coc-vim.
RUN curl -o /tmp/lts -sL install-node.vercel.app/lts && bash /tmp/lts --yes

RUN <<EOF
  set -e
  useradd \
    --home-dir /home/$username \
    --gid users \
    --uid $userid \
    --shell /bin/bash \
    --create-home \
    $username
  echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF

USER $username
WORKDIR /home/$username
RUN mkdir -p bin

COPY \
    /start_proxy_verifier_project \
    /gh-md-toc \
    /build_static \
    /home/$username/bin/

# Alas, COPY is not run as USER, and older docker version do not have --chown
# for COPY.
RUN <<EOF
  set -e
  sudo chown $username:nobody /home/$username/bin/*
    chmod 755 /home/$username/bin/*
EOF

COPY \
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
RUN <<EOF
  set -e
  nvim +'PlugInstall --sync' +qa
  nvim +'CocInstall -sync coc-clangd coc-pyright coc-json coc-sh' +qall
EOF

# Install the latest version of clang.
RUN <<EOF
  set -e
  sudo dnf clean metadata
  sudo dnf install -y clang clang-tools-extra
EOF

RUN <<EOF
  set -e
  git config --global user.name "$git_username"
  git config --global user.email $git_email
EOF

# Use a recent fish and oh-my-zsh.
RUN sudo dnf install -y zsh util-linux-user
RUN sh -c "`wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -`"
RUN <<EOF
  set -e
  git clone https://github.com/zsh-users/zsh-autosuggestions /home/${username}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-history-substring-search /home/${username}/.oh-my-zsh/custom/plugins/zsh-history-substring-search
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${username}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
EOF

COPY .zshrc /home/$username/
COPY aliases.zsh /home/$username/.oh-my-zsh/custom/aliases.zsh
COPY bneradt.zsh-theme /home/$username/.oh-my-zsh/custom/themes/bneradt.zsh-theme
RUN <<EOF
  set -e
  sudo chown -R $username:nobody \
        .zshrc \
        .oh-my-zsh/
EOF

RUN sudo chsh -s /usr/bin/zsh ${username}

# Install fzf, which adds shell shortcuts.
RUN <<EOF
  set -e
  mkdir -p /home/${username}/src
  cd /home/${username}/src
  git clone https://github.com/junegunn/fzf.git
  cd fzf
  ./install --all
EOF

WORKDIR /home/$username

# Keep this at the end to clean up the dnf cache.
RUN sudo dnf clean all
