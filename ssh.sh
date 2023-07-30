#!/bin/bash

pi_ip=$(lanipof '')
echo "Pi IP = $pi_ip"

ssh user@$pi_ip
