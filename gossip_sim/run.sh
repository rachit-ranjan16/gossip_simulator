mix deps.get
mix compile
mix run 
mix escript.build
./gossip_sim 1000 $1 $2
