.DEFAULT_GOAL: init

LOCAL_DIR=${HOME}/.local
BIN_DIR=${LOCAL_DIR}/bin
CONFIG_DIR=${HOME}/.config
SRC_DIR=${HOME}/.local/bootstrap

.PHONY: init
init: apt-fast apt-ensure-latest apt-base skel
	make git python ruby golang docker
	make i3 nvim urxvt zsh

.PHONY: list
list:
	@grep -E "^.PHONY" Makefile | awk '{ print $$2}'

.PHONY: clean
clean:
	rm -rfI ${SRC_DIR}

.PHONY: apt-base
apt-base:
	sudo apt install -y vim zsh git tmux silversearcher-ag mtr \
		daemontools htop most kafkacat

.PHONY: apt-fast
apt-fast:
	sudo add-apt-repository -y ppa:apt-fast/stable
	sudo apt update
	sudo apt install -y apt-fast

.PHONY: apt-upgrade
apt-ensure-latest:
	sudo apt update
	sudo apt upgrade -y

.PHONY: backgrounds
backgrounds:
	sudo apt install -y feh
	ln -sf ${PWD}/bin/set-random-background ${BIN_DIR}
	ln -sf ${PWD}/backgrounds ${LOCAL_DIR}/

.PHONY: docker
DOCKER_FINGERPRINT=0EBFCD88
DOCKER_GROUP=docker
LSB_RELEASE=$(shell lsb_release -cs)
DOCKER_COMPOSE_VERSION=1.17.1
UNAME_S=$(shell uname -s)
UNAME_M=$(shell uname -m)
docker:
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint ${DOCKER_FINGERPRINT}
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"
	sudo apt update
	sudo apt install -y docker-ce
	sudo groupadd docker || true
	sudo usermod -aG docker ${USER} || true
	sudo systemctl enable docker
	curl -L \
		https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${UNAME_S}-${UNAME_M} \
		-o ${BIN_DIR}/docker-compose && \
		chmod +x ${BIN_DIR}/docker-compose

.PHONY: git
git:
	sudo apt install -y git
	ln -svf ${PWD}/dotfiles/gitconfig ${HOME}/.gitconfig
	ln -svf ${PWD}/bin/git-root ${BIN_DIR}

.PHONY: gimp
GIMP_VERSION=2.8.16-1ubuntu1.1
GIMP_DIR=${HOME}/.gimp-2.8
gimp:
	sudo apt install -y gimp=${GIMP_VERSION}
	ln -sf ${PWD}/dotfiles/gimp-sessionrc ${GIMP_DIR}/sessionrc

.PHONY: golang
GO_VERSION=1.9
GOROOT=/usr/lib/go-${GO_VERSION}
golang:
	sudo add-apt-repository -y ppa:gophers/archive
	sudo apt update
	sudo apt install -y golang-${GO_VERSION}-go
	mkdir -p ${SRC_DIR}/golang/src
	PATH="${GOROOT}/bin:$$PATH" go get -u github.com/kardianos/govendor

.PHONY: i3
I3_DIR=${SRC_DIR}/i3-gaps
I3_VERSION=4.14.1
i3:
	# Dependencies
	sudo add-apt-repository -y ppa:aguignard/ppa
	sudo apt update
	sudo apt install -y libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev \
	libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev \
	libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev \
	libxkbcommon-x11-dev autoconf libxcb-xrm-dev libxcb-xrm-dev xinit gnome-session
	# i3
	[ -d ${I3_DIR} ] || git clone https://github.com/Airblader/i3 ${I3_DIR}
	cd ${I3_DIR}; \
		git fetch --tags; \
		git reset --hard ${I3_VERSION}; \
		autoreconf --force --install; \
		rm -rf build; \
		mkdir -p build; \
		cd build; \
		../configure --prefix=${LOCAL_DIR} --sysconfdir=${LOCAL_DIR}/etc --disable-sanitizers; \
		make; \
		make install
	# dotfiles
	mkdir -p ${CONFIG_DIR}/i3
	sudo cp ${PWD}/dotfiles/xsession.desktop /usr/share/xsessions/xsession.desktop
	ln -svf ${PWD}/dotfiles/xsession ${HOME}/.xsession
	ln -svf ${PWD}/dotfiles/xsession ${HOME}/.xinitrc
	ln -svf ${PWD}/dotfiles/i3 ${CONFIG_DIR}/i3/config
	# stuff to make i3 better
	make backgrounds i3blocks rofi i3-utils nerdfonts parcellite gimp xscreensaver

.PHONY: i3blocks
I3BLOCKS_DIR=${SRC_DIR}/i3blocks
I3BLOCKS_VERSION=1.4
i3blocks:
	# i3blocks
	[ -d ${I3BLOCKS_DIR} ] || git clone https://github.com/vivien/i3blocks ${I3BLOCKS_DIR}
	cd ${I3BLOCKS_DIR}; \
		git fetch --tags; \
		git reset --hard ${I3BLOCKS_VERSION}; \
		make clean; \
		make
	ln -svf ${I3BLOCKS_DIR}/i3blocks ${BIN_DIR}
	# dotfiles
	mkdir -p ${CONFIG_DIR}/i3blocks
	ln -svf ${PWD}/dotfiles/i3blocks ${CONFIG_DIR}/i3blocks/config

.PHONY: i3-utils
i3-utils:
	sudo apt install -y pavucontrol pasystray xfce4-taskmanager xfce4-power-manager shutter unclutter

.PHONY: nerdfonts
NERDFONTS_DIR=${SRC_DIR}/nerd-fonts
NERDFONTS_VERSION=v1.1.0
nerdfonts:
	[ -d ${NERDFONTS_DIR} ] || git clone -b ${NERDFONTS_VERSION} --depth 1 https://github.com/ryanoasis/nerd-fonts ${NERDFONTS_DIR}
	cd ${NERDFONTS_DIR}; \
	git checkout ${NERDFONTS_VERSION}; \
	bash install.sh --otf FantasqueSansMono || true

.PHONY: nvim
NVIM_DIR=${SRC_DIR}/neovim
NVIMRC_PATH=${CONFIG_DIR}/nvim/init.vim
NVIM_VERSION=v0.2.0
VUNDLE_DIR=${SRC_DIR}/vundle.vim
VUNDLE_VERSION=v0.10.2
nvim:
	sudo apt-get install -y libtool libtool-bin autoconf automake cmake g++ pkg-config unzip xsel
	# Neovim
	[ -d ${NVIM_DIR} ] || git clone https://github.com/neovim/neovim ${NVIM_DIR}
	cd ${NVIM_DIR}; \
		git fetch --tags; \
		git reset --hard ${NVIM_VERSION}; \
		make clean; \
		make CMAKE_BUILD_TYPE="RelWithDebInfo" CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${LOCAL_DIR}"; \
		make install
	mkdir -p ${HOME}/.vim/undo ${HOME}/.vim/swp
	mkdir -p $(shell dirname ${NVIMRC_PATH})
	pip install --user --upgrade neovim
	$(shell PATH=${RBENV_DIR}/bin:$$PATH rbenv which gem) install --no-rdoc --no-ri neovim
	# vimrc
	ln -svf ${PWD}/dotfiles/vimrc ${NVIMRC_PATH}
	ln -svf ${NVIMRC_PATH} ${HOME}/.vimrc
	# vundle
	[ -d ${VUNDLE_DIR} ] || git clone https://github.com/VundleVim/Vundle.vim.git ${VUNDLE_DIR}
	cd ${VUNDLE_DIR}; \
		git fetch --tags; \
		git reset --hard ${VUNDLE_VERSION}
	mkdir -p ${HOME}/.vim/bundle
	ln -svf ${VUNDLE_DIR} ${HOME}/.vim/bundle/Vundle.vim
	PATH="${BIN_DIR}:$$PATH" nvim +PluginInstall +qall
	# YouCompleteMe
	cd ${HOME}/.vim/bundle/YouCompleteMe; \
		PATH="${GOROOT}/bin:$$PATH" ./install.py --gocode-completer

.PHONY: parcellite
parcellite:
	sudo apt install -y parcellite
	mkdir -p ${CONFIG_DIR}/parcellite
	ln -sf ${PWD}/dotfiles/parcelliterc ${CONFIG_DIR}/parcellite/parcelliterc

.PHONY: python
python:
	sudo apt install -y python-pip
	pip install --user --upgrade setuptools pip
	pip install --user --upgrade ipython grip

.PHONY: rofi
ROFI_DIR=${SRC_DIR}/rofi
ROFI_VERSION=1.3.1
rofi:
	# dependencies
	sudo apt install -y bison flex libxcb-ewmh-dev librsvg2-dev libpango1.0-dev \
	libpangocairo-1.0-0 libcairo2-dev libstartup-notification0-dev libxcb-xkb-dev
	# rofi
	[ -d ${ROFI_DIR} ] || git clone https://github.com/DaveDavenport/rofi ${ROFI_DIR}
	cd ${ROFI_DIR}; \
		git fetch --tags; \
		git reset --hard ${ROFI_VERSION}; \
		git submodule update --init; \
		autoreconf -i; \
		rm -rf build; \
		mkdir build; \
		cd build; \
		../configure --prefix=${LOCAL_DIR}; \
		make; \
		make install
	# bin scripts based on rofi
	ln -svf ${PWD}/bin/rofi-system-mode ${BIN_DIR}
	ln -svf ${PWD}/bin/rofi-monitor-mode ${BIN_DIR}

.PHONY: ruby
RBENV_DIR=${SRC_DIR}/rbenv
RBENV_VERSION=1.1.1
RUBYBUILD_DIR=${SRC_DIR}/ruby-build
RUBY_VERSION=2.4.2
RUBY_PATH=${RBENV_DIR}/versions/${RUBY_VERSION}
ruby:
	sudo apt install -y software-properties-common libssl-dev libreadline-dev zlib1g-dev
	ln -svf ${PWD}/dotfiles/gemrc ${HOME}/.gemrc
	[ -d ${RBENV_DIR} ] || git clone https://github.com/rbenv/rbenv ${RBENV_DIR}
	cd ${RBENV_DIR}; \
		git fetch --tags; \
		git reset --hard ${RBENV_VERSION}; \
		src/configure; \
		make -C src
	ln -svf ${RBENV_DIR} ${HOME}/.rbenv
	mkdir -p ${RBENV_DIR}/plugins
	[ -d ${RUBYBUILD_DIR} ] || git clone https://github.com/rbenv/ruby-build ${RUBYBUILD_DIR}
	cd ${RUBYBUILD_DIR}; \
		git fetch --tags; \
		git reset --hard ${RUBYBUILD_VERSION}
	ln -svf ${RUBYBUILD_DIR} ${RBENV_DIR}/plugins/ruby-build
	PATH="${RBENV_DIR}/bin:$$PATH" rbenv install --verbose --skip-existing ${RUBY_VERSION}
	PATH="${RBENV_DIR}/bin:$$PATH" rbenv global ${RUBY_VERSION}
	PATH=${RUBY_PATH}/bin:$$PATH gem install bundler pry activesupport

.PHONY: skel
skel:
	mkdir -p ${SRC_DIR} ${CONFIG_DIR} ${BIN_DIR}
	mkdir -p ${HOME}/src

.PHONY: urxvt
BASE16SHELL_DIR=${SRC_DIR}/base16-shell
BASE16SHELL_VERSION=master
TABBEDEX_DIR=${SRC_DIR}/tabbedex-urxvt
urxvt:
	sudo apt install -y rxvt-unicode-256color
	ln -svf ${PWD}/dotfiles/Xresources ${HOME}/.Xresources
	[ -d ${BASE16SHELL_DIR} ] || git clone https://github.com/chriskempson/base16-shell ${BASE16SHELL_DIR}
	cd ${BASE16SHELL_DIR}; \
	git fetch --tags; \
	git reset --hard ${BASE16SHELL_VERSION}
	ln -svf ${BASE16SHELL_DIR} ${CONFIG_DIR}/base16-shell
	[ -d ${TABBEDEX_DIR} ] || git clone https://github.com/shaggytwodope/tabbedex-urxvt ${TABBEDEX_DIR}
	cd ${TABBEDEX_DIR}; \
		sudo cp tabbedex /usr/lib/urxvt/perl/tabbedex

.PHONY: xscreensaver
xscreensaver:
	sudo apt install -y xscreensaver xscreensaver-gl-extra
	ln -sf ${PWD}/dotfiles/xscreensaver ${HOME}/.xscreensaver

.PHONY: zsh
FZF_DIR=${SRC_DIR}/fzf
FZF_VERSION=0.17.1
OHMYZSH_DIR=${SRC_DIR}/oh-my-zsh
OHMYZSH_THEME="drewfradette"
ZSHSYNTAX_DIR=${SRC_DIR}/zsh-syntax-highlighting
ZSHSYNTAX_VERSION=0.6.0
zsh:
	sudo apt install -y zsh
	[ -d ${OHMYZSH_DIR} ] || git clone https://github.com/robbyrussell/oh-my-zsh ${OHMYZSH_DIR}
	ln -svf ${OHMYZSH_DIR} ${HOME}/.oh-my-zsh
	ln -svf ${PWD}/.zshrc ${HOME}/.zshrc
	chsh --shell /usr/bin/zsh
	ln -svf ${PWD}/dotfiles/zshrc ${HOME}/.zshrc
	ln -svf ${PWD}/dotfiles/${OHMYZSH_THEME}.zsh-theme ${OHMYZSH_DIR}/themes
	[ -d ${ZSHSYNTAX_DIR} ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSHSYNTAX_DIR}
	cd ${ZSHSYNTAX_DIR}; \
	git fetch --tags; \
	git reset --hard ${ZSHSYNTAX_VERSION};
	[ -d ${FZF_DIR} ] || git clone https://github.com/junegunn/fzf ${FZF_DIR}
	cd ${FZF_DIR}; \
	git fetch --tags; \
	git reset --hard ${FZF_VERSION}; \
	./install --key-bindings --completion --no-fish --no-bash --no-update-rc
