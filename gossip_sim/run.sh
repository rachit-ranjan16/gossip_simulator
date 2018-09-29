mix deps.get
mix compile
mix run 
mix escript.build
./gossip_sim $1 $2 $3
