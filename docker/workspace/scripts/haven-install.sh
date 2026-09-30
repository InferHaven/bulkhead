#!/bin/bash
###############################################################################
# haven-install — compatibility shim
#
# This command has been absorbed into 'bulkhead apt'. This shim is kept so that
# existing scripts and muscle memory continue to work.
#
# Preferred usage going forward:
#   bulkhead apt install <package> [package2 ...]
#   bulkhead apt remove <package>
#   bulkhead apt list
#   bulkhead apt upgrade
###############################################################################
case "${1:-}" in
  --list)    exec bulkhead apt list ;;
  --remove)  shift; exec bulkhead apt remove "$@" ;;
  --upgrade) exec bulkhead apt upgrade ;;
  --help|-h) exec bulkhead apt help ;;
  -*)        echo "Unknown option: $1. Use 'bulkhead apt' instead." >&2; exit 1 ;;
  *)         exec bulkhead apt install "$@" ;;
esac
