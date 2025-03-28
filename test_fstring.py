import sys
import platform
version = sys.version_info
message = f"Hello from Python {version.major}.{version.minor}.{version.micro}!"
print(message)
if version.major < 3 or (version.major == 3 and version.minor < 6): sys.exit(1)
sys.exit(0)