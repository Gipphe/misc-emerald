# Oblig 1

Victor Nascimento Bakke

victonba@ifi.uio.no

## Exercise 1 - Barriers

Source file: `ex1_barrier.m`

Output file: `ex1_barrier.txt`

The default configuration for docker, in which I run the code I've written for
this entire oblig, has 2 processing cores available. This is reflected in the
output of the program.

Two of the processes are able to enter and then leave the barrier at a time due
to there being 2 cores. If we want to ensure all processes have time to enter
the barrier before any process start leaving, we will technically have to have
another barrier for the "leaving" action.

## Exercise 2 - Producer/Consumer

Source file: `ex2_producer_consumer.m`

Output file: `ex2_producer_consumer.txt`

## Exercise 3 - Kilroy timing: local and on Planetlab

Source file: `ex3_kilroy.m`

Output file: `ex3_kilroy.txt`

At the time I tried to do the first part of this exercise, only 2 of the 4
machines as IFI that I know of were available (`jordin` and `vatn`. `kennen`
and `ashe` were down), so I started the script on `vatn`, and had two emerald
machines on `jordin` (referred to as `jordin 1` and `jordin 2` in the output
file).

I was unable to make the script return home on IFI's machines, as the `home`
node turned `unavailable` when reaching the final node. Unsure of the reasons
for this. As such, to get any kind of sensible output from the script, I
adapted it to optionally write its final output on whichever node it ended up
on.

For the planetlab part of this exercise, I chose the following nodes:

- `ple1.cesnet.cz` (Prague, Czech Republic)
- `cse-white.cse.chalmers.se` (Gotenburg, Sweden)
- `kulcha.mimuw.edu.pl` (Warsaw, Poland)
- `planetlab1.xeno.cl.cam.ac.uk` (Cambridge, United Kingdom)

For no particular reason, I chose `kulcha.mimuw.edu.pl` to host my program.
