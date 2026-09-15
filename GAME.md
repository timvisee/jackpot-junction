# Jackpot Junction

This document describes the game Jackpot Junction. It defines its gameplay,
mechanics, features and technology stack. This document will be updated as the
game development progresses with new ideas, decisions and features.

## Gameplay

The base gameplay is a multiplayer arena. Every player gets their own kart and
competes against other players to collect the highest score. The game is
designed to be fast-paced and competitive, with players needing to use their
skills and strategy to outmaneuver their opponents.

### Arena

The arena itself is a fixed environment with various obstacles, power-ups, and
coins scattered throughout. The borders are clearly defined so that players are
contained within the arena. Players can collect coins to increase their score
and power-ups to gain temporary advantages over their opponents.

We start with a single map, but in the future it should be possible to add more
maps to the game, each with its own unique layout and challenges.

### Kart

Players control their very own kart, which can be customized with different
skins and colors.

The karts are designed to be fast and agile, allowing players to quickly
navigate the arena and avoid obstacles. When going fast and making tight
corners, the karts drift a bit in a satisfying way.

A player can die when they hit a bullet, some obstacles or another player, and
will respawn after a short delay.

### Scoring

Players will collect points and mult (multiplier). When a player dies, the
product of their points and mult will be added to their score. After which their
points and mult will reset.

Players can also collect jokers, which will affect their points and mult.

The game ends when a player reaches a certain score or when a time limit is
reached, at which point the player with the highest score is declared the
winner.

## Visuals

The game will have a colorful and vibrant art style, with a cartoonish
aesthetic. The arena will be designed to be visually appealing and easy to
navigate, with clear visual cues for obstacles and power-ups.

The game shows you a top down view of the arena, with the camera positioned
above the action. The objects itself are 3D, but the camera is fixed and does
not rotate, though it might move along with your kart.

## Inspiration

- Wii Tanks - basic arena layout, looks, perspective, camera angle and controls
- Balatro - points (will be coins in this game), multipliers, jokers
- Bullet hell - bullet-hell like chaos

## Technology stack

Use Godot as the game engine, and GDScript as the programming language.

We start with a single-player mode, but the game will be designed to support
multiplayer functionality in the future.

Use Godot's built-in networking capabilities to implement multiplayer
functionality. The game will be developed for PC and console platforms, with the
option for mobile support and on-screen controls later.

