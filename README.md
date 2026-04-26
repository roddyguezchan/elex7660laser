# S.C.O.P.E.

The Stepper Controlled Optical Positioning Engine (or SCOPE for short) is a laser data transmission and positioning system designed as our final project for the ELEX 7660 Digital System Design course at the British Columbia Institute of Technology. The project was assigned a timeline of five weeks, with a demo of what was accomplished at the end of the period. SCOPE's main goal is to center a laser onto a target for optimal data transmission by use of a gimbal motor system on the transmitter. The receiver, which is handheld for demonstration, can be moved around at a moderate pace and followed by the transmitter. While data transmission via laser was not completed due to time constraints with the project, the system is ready for its implementation.

## Theory of Operation

In normal operation, the transmitter looks for the receiver by scanning the laser in its search area. Since the laser is highly directional, a quadrant photodiode (QPD) on the receiver is used to determine where to aim the laser and to receive the incoming data at the same time. When the laser hits the QPD, a message is sent to the transmitter via infrared to confirm that the receiver is in range and can start locking into the center of the QPD. To do so, the receiver tells the transmitter where the laser is hitting on the QPD, and the transmitter corrects for that in order to maintain its aim on the center. In the event the laser is lost during reception, the transmitter uses a taxicab spiral to find the receiver again.

The full report, including extensive coverage of testing and full theory of operation, can be found [here](/other/ELEX%207660%20Final%20Project.pdf).

## Project Objectives

Our project was assigned goals that were to be met by the date of the demo. These objectives, as well as what was accomplished, are as follows:

✅ **Azimuth (yaw) and elevation (pitch) tracking of a moving retroreflective target using a laser**
```
- Yaw and pitch tracking completed using stepper motors
- Target is not retroreflective, but communicates the position of the laser instead
```
✅ **Effective tracking/transmission with the target further than 2m and of size less than 10cm**
```
- Testing of the system was done primarily at 2m and greater
- Target was only 1 inch in diameter
```
In addition, the following stretch goals were assigned:

✅ **Target acquisition**
```
- Implemented using a taxicab spiral search algorithm 
```
🟨 **Data communication with the target**
```
- Implemented using a taxicab spiral search algorithm 
```
🟨 **Able to acquire/track at long range**
```
- Depending on the definition of long-range, this was accomplished.
- The given distance goal was two metres. The testing distance we used in demo was three metres (150%) and the system tracked and acquired well.
```
❎ **Able to track target moving at high-speed**
```
- Given the constraints of our system, the speed is mostly limited by the data rate of our infrared implementation and the angular resolution of the gimbal’s steppers.
```

## Pre-compile notes

Before compiling the project in Quartus, ensure that the **ccom.qsys** HDL files have been generated for both the transmitter and receiver projects in the Platform Designer. This module is responsible for the communication between the hardware and the C++ software executed in RiscFree.
