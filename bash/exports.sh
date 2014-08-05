#!/bin/bash

export PS1='\[\033[0;31m\]λ\[\033[0;36m\] \w\[\033[00m\]$(__git_ps1 " \[\033[0;35m\] %s")\[\033[00m\]: '
export EDITOR=vim
export PATH=$PATH:$HOME/bin
