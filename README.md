# Liquid Cooling Control for AI Servers

> Simulink/Simscape thermal-fluid modeling + Arduino hardware test rig + RL-based cooling control.
> A portfolio project: from simulation to hardware (sim-to-real).

## What this is

A desktop-scale liquid cooling loop that mimics direct-to-chip cooling for AI servers:
heater cartridge (40 W) plays the role of the compute chip, a water block + 120 mm
radiator + pump form the cooling loop, and an Arduino closes the loop —
reading temperatures and driving pump/fan/heater via PWM.

The end goal: a controller that holds chip temperature under varying compute load,
first designed in simulation, then validated on real hardware —
and finally an RL agent trained in simulation and deployed to the rig
(the same idea Meta uses for data-center cooling optimization).

## System architecture

Reservoir -> Pump -> Cold plate (+ 40W heater = "chip") -> Radiator + Fan -> back to reservoir.
Arduino UNO R4 reads 3x DS18B20 temp sensors and drives pump/fan/heater via MOSFET PWM drivers.
PC runs MATLAB/Simulink in External Mode for tuning and monitoring.

## Roadmap

- Phase A — Simulation: Simscape thermal-fluid plant model; PID to MPC controller comparison in simulation.
- Phase B — Hardware rig: build the Arduino test rig; hardware-in-the-loop validation; sim-vs-hardware calibration.
- Phase C — RL control: train an RL agent (Reinforcement Learning Toolbox) in simulation; deploy to hardware; sim-to-real comparison.

## Hardware (~$305 incl. Arduino UNO Q for side projects)

Arduino UNO R4 WiFi (rig controller) x1; Arduino UNO Q 4GB (side projects) x1;
DS18B20 waterproof temp sensor x3; IRF520 MOSFET driver module x3;
12V 5A power supply x1; 12V mini brushless submersible pump x1;
12V 40W heater cartridge (6x20mm) x1; copper CPU water block G1/4 x1;
120mm radiator + 120mm high-static-pressure fan; silicone tubing 8mm ID 2m;
G1/4 barb fittings x4; thermal paste, breadboard, dupont wires.

## Repo layout

sim/ — Simulink/Simscape models (Phase A)
hardware/ — Arduino wiring, BOM, rig photos (Phase B)
rl/ — RL training scripts and deployed policy (Phase C)
docs/ — notes, sim-vs-hardware comparisons

## Status

- Project scoped and BOM finalized (Oct 2026)
- Hardware ordered after house move (Oct 23, 2026)
- Phase A: Simscape model + PID/MPC — next
- Phase B: rig build + HIL validation
- Phase C: RL sim-to-real
