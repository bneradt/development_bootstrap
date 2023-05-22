FROM arm64v8/ubuntu:22.04

ARG username
ARG userid
ARG git_username
ARG git_email

# So that installing pkg-config does not interactively prompt during the image
# creation process.
ARG DEBIAN_FRONTEND=noninteractive

# Packages for building Proxy Verifier and its dependencies.
RUN apt-get update; \
    apt-get install -y pipenv autoconf libtool pkg-config git curl clangd

# Install Bear to generate compile_commands.json for clangd autocompletion.
# This takes a while, but the packaged Ubuntu version installed via apt-get is
# 2.x and we need the newer 3.x.
RUN apt-get install -y cmake pkg-config libfmt-dev libspdlog-dev \
                       nlohmann-json3-dev libgrpc++-dev \
                       protobuf-compiler-grpc libssl-dev
RUN git clone https://github.com/rizsotto/Bear.git; \
    cd Bear/; \
    cmake -DENABLE_UNIT_TESTS=OFF -DENABLE_FUNC_TESTS=OFF; \
    make -j $(nproc) all; \
    make install

# Install the library dependencies in /opt.
RUN apt-get install -y sudo
WORKDIR /var/tmp
RUN \
    git clone https://github.com/yahoo/proxy-verifier.git; \
    cd proxy-verifier; \
    bash tools/build_library_dependencies.sh /opt

# Python linting tools.
RUN pip install --upgrade pep257 mypy yapf autopep8 flake8 pylint pydocstyle pycodestyle

# User-specific specifications.
RUN apt-get install -y wget silversearcher-ag tmux exuberant-ctags

# The packaged version of neovim is old. Install a recent one.  This would be
# easier if fuse worked better in a docker build, but there doesn't seem to be
# an easy way to grant privileged access to a docker build run. So we have to
# do things by hand.
RUN apt-get install -y ninja-build gettext libtool libtool-bin autoconf \
                       automake cmake g++ pkg-config unzip curl doxygen
RUN git clone https://github.com/neovim/neovim; \
    cd neovim; \
    git checkout v0.7.0; \
    make -j `nproc`; \
    make install


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
    /start_proxy_verifier_project \
    /gh-md-toc \
    /build_static \
    /home/$username/bin/

# Alas, COPY is not run as USER, and older docker version do not have --chown
# for COPY.
RUN \
    sudo chown $username:nogroup /home/$username/bin/*; \
    chmod 755 /home/$username/bin/*

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

RUN mkdir -p .vim/swap

RUN mkdir .git_template
COPY .git_template .git_template

RUN mkdir -p .config/nvim
COPY init.vim .config/nvim
COPY coc-settings.json .config/nvim

RUN \
    sudo chown -R $username:nogroup \
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

RUN  \
  git config --global user.name "$git_username"; \
  git config --global user.email $git_email

# Install zsh
RUN sudo apt install -y zsh
RUN sh -c "`wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -`"
RUN \
   git clone https://github.com/zsh-users/zsh-autosuggestions /home/${username}/.oh-my-zsh/custom/plugins/zsh-autosuggestions; \
   git clone https://github.com/zsh-users/zsh-history-substring-search /home/${username}/.oh-my-zsh/custom/plugins/zsh-history-substring-search; \
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${username}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

COPY .zshrc /home/$username/
COPY aliases.zsh /home/$username/.oh-my-zsh/custom/aliases.zsh
COPY bneradt.zsh-theme /home/$username/.oh-my-zsh/custom/themes/bneradt.zsh-theme
RUN \
    sudo chown -R $username:nogroup \
        .zshrc \
        .oh-my-zsh/

RUN sudo chsh -s /usr/bin/zsh ${username}

# Install fzf
RUN \
  mkdir -p /home/${username}/src; \
  cd /home/${username}/src; \
  git clone https://github.com/junegunn/fzf.git; \
  cd fzf; \
  ./install

# Get terminal fonts for the zsh prompt working.
RUN \
    sudo apt-get -y install locales && \
    sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sudo locale-gen && \
    sudo update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Update pipenv for when we run pipenv install on recent versions of Python3.
RUN python3 -m pip install --upgrade pip pipenv

# Install the required node 17 for Copilot, which does not support 18 and above yet.
# https://github.com/community/community/discussions/16298
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
RUN . /home/${username}/.nvm/nvm.sh && nvm install 17 && nvm use 17
SHELL ["/bin/bash", "--login", "-c"]
