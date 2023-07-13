FROM ubuntu:23.04

ARG username
ARG userid
ARG git_username
ARG git_email

# So that installing pkg-config does not interactively prompt during the image
# creation process.
ARG DEBIAN_FRONTEND=noninteractive

# User-specific specifications.
RUN apt-get update; \
    apt-get install -y \
        git pipenv cmake clang golang python3 python3-pip nodejs \
        sudo wget silversearcher-ag tmux exuberant-ctags fzf curl \
        neovim \
        python3-autopep8 python3-flake8

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
    /start_toy_project \
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
RUN nvim +'CocInstall -sync coc-pyright coc-json coc-sh' +qall

RUN  \
  git config --global user.name "$git_username"; \
  git config --global user.email $git_email
