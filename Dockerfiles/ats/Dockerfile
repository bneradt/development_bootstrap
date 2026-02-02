# Base image.
FROM ci.trafficserver.apache.org/ats/fedora:43

# ARG stuff for the build.
ARG username
ARG userid
ARG git_username
ARG git_email

#------------------
# My customization.
#------------------
# User-specific specifications.
RUN <<EOF
  set -e
  dnf -y update

  dnf install -y glibc-locale-source glibc-langpack-en
  localedef -i en_US -f UTF-8 en_US.UTF-8

  dnf install -y \
    ctags the_silver_searcher tmux man-pages neovim bear git gh tcpdump gdb net-tools \
    zsh util-linux-user \
    clang clang-tools-extra graphviz

  dnf clean all
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
    /auth_gh_yahoo \
    /auth_gh_asf \
    /auth_jira_cli \
    /bisect_with_autest \
    /build_ats \
    /build_ats_core \
    /build_ats_coverage \
    /build_ats_not_quic \
    /build_ats_quiche \
    /build_ats_docs \
    /cedge \
    /clean_build_test \
    /cos \
    /install_extensions \
    /normalize_log \
    /start_ats_project \
    /pretty_print_json \
    /reset_agent \
    /home/$username/bin/

# Alas, COPY is not run as USER, and older docker version do not have --chown
# for COPY.
RUN <<EOF
  set -e
  sudo chown $username:nobody /home/$username/bin/*
  chmod 755 /home/$username/bin/*
EOF

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

RUN mkdir -p src
COPY CMakeUserPresets.json src

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
        .vimrc \
        src

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

RUN <<EOF
  set -e
  git config --global user.name "$git_username"
  git config --global user.email $git_email
EOF

# Use a recent fish and oh-my-zsh.
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
  echo 'export PATH=/opt/bin:/opt/go/bin:${PATH}' >> /home/${username}/.zshrc
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

# Bake in a local clone of ATS to save time on container creation
RUN <<EOF
  set -e
  my_repo_fork=https://github.com/${username}/trafficserver.git
  cd /home/${username}/src
  git clone ${my_repo_fork} ts_asf
  cd ts_asf
  git remote add upstream https://github.com/apache/trafficserver.git
  git remote update
  git checkout master
  git remote set-url origin git@github.com:${username}/trafficserver.git
  git remote set-url upstream git@github.com:apache/trafficserver.git

  # Now, compress the repository for the image.
  git repack -adf
  git gc --aggressive
EOF

WORKDIR /home/$username
