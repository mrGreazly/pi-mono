#!/bin/sh
# Installs or updates pi-fixed (pi built from the pi-fixed branch of mrGreazly/pi-mono) on Linux and macOS.
# Usage: curl -fsSL https://raw.githubusercontent.com/mrGreazly/pi-mono/pi-fixed/install-pi-fixed.sh | sh
set -eu

repo="mrGreazly/pi-mono"
install_dir="$HOME/.local/share/pi-fixed"
bin_dir="$HOME/.local/bin"

case "$(uname -s)" in
	Linux) os="linux" ;;
	Darwin) os="darwin" ;;
	*) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
	x86_64 | amd64) arch="x64" ;;
	aarch64 | arm64) arch="arm64" ;;
	*) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
url="https://github.com/$repo/releases/latest/download/pi-$os-$arch.tar.gz"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "Downloading $url"
curl -fsSL "$url" -o "$work/pi.tar.gz"
tar -xzf "$work/pi.tar.gz" -C "$work"

rm -rf "$install_dir"
mkdir -p "$(dirname "$install_dir")" "$bin_dir"
mv "$work/pi" "$install_dir"
ln -sf "$install_dir/pi" "$bin_dir/pi"

echo "Installed pi-fixed $("$install_dir/pi" --version) to $install_dir"
case ":$PATH:" in
	*":$bin_dir:"*) ;;
	*) echo "Add $bin_dir to PATH to run 'pi'." ;;
esac
resolved="$(command -v pi || true)"
if [ -n "$resolved" ] && [ "$resolved" != "$bin_dir/pi" ]; then
	echo "Warning: 'pi' currently resolves to $resolved, not pi-fixed. Remove that pi or put $bin_dir first in PATH."
fi
