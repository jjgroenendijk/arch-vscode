## 2024-05-23 - [Docker Optimization: Pre-compiled Binaries]
**Learning:** Building tools from source in Dockerfiles (like `yay` from AUR) can drag in massive build dependencies (like Go) that remain in the layer unless carefully managed. Using pre-compiled binaries (`yay-bin`) avoids this entirely.
**Action:** When installing AUR packages in Docker, always check for a `-bin` variant first to save build time and image size.
