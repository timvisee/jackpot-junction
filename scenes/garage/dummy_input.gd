class_name DummyInput
extends KartInput
## The controls of a kart nobody is driving: the Garage's practice dummies, GAME.md 9.4. It
## never fills anything in, so the kart sits where it was put and never shoots back.
##
## A class of its own rather than a bare [KartInput] so that a slot can say what it is. A dummy
## is named one in the standings, and a player joining takes an empty seat rather than one of
## these: walking up to the second controller should not make a practice target disappear.
