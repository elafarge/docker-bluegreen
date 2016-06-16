//
// This package consists of the most minimalistic web server ever (after hello
// world maybe). It takes 5 seconds for it to start ( :o ) to simulate bigger
// services that would take some time to be ready (ready=healthy
// load-balancer-wise) and it then replies with the list of IP addresses the
// machine/container it runs into has access to (one per interface).
//
// Author: Étienne Lafarge <etienne.lafarge@gmail.com>
//
package main

import (
	"fmt"
	"net"
	"net/http"
	"time"
)

// Handler for the "/" route, it lists the network interface addresses
// accessible on the machine this program is running onto and puts that in the
// HTTP response, along with the "Hello" message.
func handler(w http.ResponseWriter, r *http.Request) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		panic(err)
	}
	my_addresses := ""
	for _, addr := range addrs {
		my_addresses += addr.String() + "; "
	}
	fmt.Fprintf(w, "Hello %s", my_addresses)
}

func main() {
	fmt.Println("Initializing our maxi web server (takes around 5 seconds)...")
	time.Sleep(time.Duration(5) * time.Second)
	http.HandleFunc("/", handler)
	fmt.Println("Init. done, we're ready to receive and process requests...")
	http.ListenAndServe(":8000", nil)
}
