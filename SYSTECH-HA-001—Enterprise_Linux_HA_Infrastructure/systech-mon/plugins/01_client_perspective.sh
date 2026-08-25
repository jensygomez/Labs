#!/bin/bash
echo -e "${C_BOLD}👤 CLIENT PERSPECTIVE (VIP: ${VIP})${C_RESET}"
echo -e "────────────────────────────────────────────────────────────"

HTTP_START=$(date +%s%N)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://${VIP}/")
HTTP_END=$(date +%s%N)
LATENCY=$(echo "scale=3; ($HTTP_END - $HTTP_START) / 1000000000" | bc)

if [ "$HTTP_CODE" == "200" ]; then HTTP_COLOR="$C_GREEN"
elif [ "$HTTP_CODE" == "502" ] || [ "$HTTP_CODE" == "000" ]; then HTTP_COLOR="$C_RED"
else HTTP_COLOR="$C_YELLOW"; fi

DNS_START=$(date +%s%N)
dig +short +time=1 +tries=1 "app01.${DOMAIN}" "@${DNS_SERVER}" > /dev/null 2>&1
DNS_END=$(date +%s%N)
DNS_LATENCY=$(echo "scale=3; ($DNS_END - $DNS_START) / 1000000000" | bc)

printf " HTTP Status: ${HTTP_COLOR}${C_BOLD}%-6s${C_RESET} | VIP Latency: ${C_YELLOW}%ss${C_RESET}\n" "$HTTP_CODE" "$LATENCY"
printf " DNS Resolve: ${C_GREEN}%-6s${C_RESET} | DNS Latency: ${C_YELLOW}%ss${C_RESET}\n" "OK" "$DNS_LATENCY"
