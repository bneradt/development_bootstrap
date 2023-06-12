FROM arm64v8/ubuntu:23.04

ARG username
ARG userid
ARG git_username
ARG git_email

# So that installing pkg-config does not interactively prompt during the image
# creation process.
ARG DEBIAN_FRONTEND=noninteractive

# Packages for building Proxy Verifier and its dependencies.
RUN apt-get update; \
    apt upgrade; \
    apt-get install -y cmake python3 pipenv autoconf libtool pkg-config git curl clangd sudo

WORKDIR /var/tmp
RUN \
    git clone https://github.com/yahoo/proxy-verifier.git; \
    cd proxy-verifier; \
    bash tools/build_library_dependencies.sh /opt/pv_libs; \
    cd /var/tmp; \
    rm -rf proxy-verifier

# User-specific specifications.
RUN apt-get install -y python3-pip wget silversearcher-ag tmux exuberant-ctags neovim bear

# Python linting tools.
RUN \
    apt-get install -y \
    python3-pep8 python3-yapf python3-mypy python3-autopep8 python3-flake8 \
    python3-pydocstyle python3-pycodestyle python3-pylint-common

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

# Install fzf. Do this from source so shortcuts are installed.
RUN \
  mkdir -p /home/${username}/src; \
  cd /home/${username}/src; \
  git clone --depth 1 https://github.com/junegunn/fzf.git; \
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

# Install the required node 17 for Copilot, which does not support 18 and above yet.
# https://github.com/community/community/discussions/16298
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
RUN . /home/${username}/.nvm/nvm.sh && nvm install 17 && nvm use 17
SHELL ["/bin/bash", "--login", "-c"]
