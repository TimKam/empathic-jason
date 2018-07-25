PORT_NUMBER=8080
lsof -i tcp:${PORT_NUMBER} | awk 'NR!=1 {print $2}' | xargs kill