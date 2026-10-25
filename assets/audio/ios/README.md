Apple-compatible audio derived from the byte-identical original release 41 OGG assets in the parent directory.

Effects are decoded to uncompressed16-bit PCM WAV with original sample rate/channels. Music is encoded to AAC-LC 256 kb/s in an M4A container for AVFoundation playback. No normalization, trimming or tempo changes are applied.

Conversion: ffmpeg -i ../NAME.ogg -c:a pcm_s16le NAME.wav
Music: ffmpeg -i ../bg_music.ogg -c:a aac -b:a 256k -movflags +faststart bg_music.m4a
