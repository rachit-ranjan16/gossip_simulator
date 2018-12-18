# GossipSim - Gossip Simulator 
### Description 
Simulate Asynchronous Gossip based Algorithms for message passing and aggregation using Elixir's Actor Model 

## Group Members 
  - Rachit Ranjan 
  - Aditya Vashist 

## Prerequisites 
  - Elixir 1.7+ Installation  
## Algorithms 
  - Gossip 
    - `gossip`
  - Push Sum 
    - `pushsum`
## Working Topologies 
  - Line 
    - `line` 
  - Imperfect Line
    - `imperfect_line`
  - Fully Connected Network
    - `fully_connected`
  - 3D Grid 
    - `grid3d`
  - Torus 

    - `torus`
  - 2D Random Grid
    - `random2d`
## Execution Instructions 
  - Navigate to gossip_sim 
  - Compile and Build 
    - mix compile
    - mix run 
    - mix escript.build
  - Execute 
    - `./gossip_sim numNodes topology algorithm` 
      - numNodes Integer 
      - topology: one of the highlighted topology keywords e.g. `line`,`random2d`, etc. 
      - algorithm: one of the highlighted algorithm keywords. e.g. `gossip` or `pushsum`
## Observations 
  - All topologies work with both algorithms 

| Topology        | MaxNetworkSize  Gossip | MaxNetworkSize PushSum |
|-----------------|------------------------|------------------------|
| Line            | 10e5                   | 2048                   |
| Imperfect Line  | 10e5                   | 2048                   |
| Fully Connected | 10e4                   | 1024                   |
| 3D Grid         | 10e3                   | 1024                   |
| Torus           | 10e4                   | 1024                   |
| 2D Random Grid  | 10e5                   | 16384                  |
