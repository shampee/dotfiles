.ONESHELL:
.POSIX:

nix:
	export ENVRC=nix
	proot-x86_64 -b ~/pkgs/nix-mnt:/nix bash
