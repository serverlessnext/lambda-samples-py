import sys

from .main import cli as main_cli


if __name__ == "__main__":
    sys.exit(main_cli(sys.argv[1:]))
