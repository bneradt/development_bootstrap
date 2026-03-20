#!/usr/bin/env sh
# Source this script to configure git env vars for ATS worktrees mounted in a container.
# Usage: source ~/bin/ats-worktree-env.sh [worktree_name]

# Detect whether the script is being sourced.
_sourced=0
if [ -n "${ZSH_VERSION:-}" ]; then
  case "$ZSH_EVAL_CONTEXT" in
    *:file) _sourced=1 ;;
  esac
elif [ -n "${BASH_VERSION:-}" ]; then
  (return 0 2>/dev/null) && _sourced=1
else
  _sourced=1
fi

if [ "$_sourced" -ne 1 ]; then
  echo "This script must be sourced." >&2
  echo "Usage: source ~/bin/ats-worktree-env.sh [worktree_name]" >&2
  exit 1
fi

if [ "$#" -gt 1 ]; then
  echo "Usage: source ~/bin/ats-worktree-env.sh [worktree_name]" >&2
  return 2
fi

_shared_root="${ATS_SHARED_ROOT:-/home/bneradt/shared}"
_worktree_root=$(basename `git worktree list --porcelain | head -1 | awk '{print $NF}'`)
_main_repo="${ATS_MAIN_REPO:-${_shared_root}/$_worktree_root}"

if [ "$#" -eq 1 ] && [ -n "$1" ]; then
  _wt_name="$1"
else
  _pwd_base=$(basename "$PWD")
  if [ -d "${_main_repo}/.git/worktrees/${_pwd_base}" ]; then
    _wt_name="${_pwd_base}"
  else
    _wt_name="targeted_cache_control"
  fi
fi

_wt_path="${_shared_root}/${_wt_name}"
_wt_git_dir="${_main_repo}/.git/worktrees/${_wt_name}"

if [ ! -d "${_main_repo}/.git" ]; then
  echo "Missing main repo git dir: ${_main_repo}/.git" >&2
  return 3
fi

if [ ! -d "${_wt_git_dir}" ]; then
  echo "Missing worktree git dir: ${_wt_git_dir}" >&2
  echo "Pass a valid worktree name: source ~/bin/ats-worktree-env.sh <name>" >&2
  return 4
fi

if [ ! -d "${_wt_path}" ]; then
  echo "Missing worktree path: ${_wt_path}" >&2
  return 5
fi

export GIT_DIR="${_wt_git_dir}"
export GIT_COMMON_DIR="${_main_repo}/.git"
export GIT_WORK_TREE="${_wt_path}"

echo "Set GIT_DIR=${GIT_DIR}"
echo "Set GIT_COMMON_DIR=${GIT_COMMON_DIR}"
echo "Set GIT_WORK_TREE=${GIT_WORK_TREE}"
