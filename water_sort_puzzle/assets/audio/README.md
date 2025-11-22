# Audio Assets

This directory contains audio files for the Water Sort Puzzle game.

## Required Audio Files

The game expects the following audio files:

- `pour.mp3` - Sound effect for liquid pouring between containers
- `success.mp3` - Sound effect for successful level completion
- `error.mp3` - Sound effect for invalid moves or errors

## File Format Requirements

- **Format**: MP3 (recommended) or other formats supported by audioplayers package
- **Quality**: 44.1kHz, 16-bit recommended for good quality and reasonable file size
- **Duration**: Keep sound effects short (0.5-2 seconds) for responsive gameplay
- **Volume**: Normalize audio levels to prevent jarring volume differences

## Current Status

The current files in this directory are placeholder text files. To enable audio in the game:

1. Replace the placeholder files with actual MP3 audio files
2. Ensure the files have the exact same names: `pour.mp3`, `success.mp3`, `error.mp3`
3. Test the audio in the game to ensure proper playback

## Audio Sources

For production use, consider:
- Creating custom sound effects
- Using royalty-free sound libraries (freesound.org, zapsplat.com)
- Purchasing professional sound effect packs
- Recording custom sounds for unique game feel

## Development Notes

The AudioManager handles missing audio files gracefully - the game will continue to work even if audio files are missing, with helpful console messages indicating which files need to be added.