FROM ci.trafficserver.apache.org/ats/rockylinux:8

ARG username
ARG userid
ARG git_username
ARG git_email

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
