#!/usr/bin/env bash
# Checks each URL: DNS resolution, final HTTP status, final resolved URL after redirects.
# Outputs pipe-delimited: num|domain|dns(ok/fail)|final_code|final_url
set -u
INPUT="urls.txt"
OUT="results.tsv"
: > "$OUT"

while IFS='|' read -r num domain desc; do
  [ -z "$num" ] && continue
  url="https://$domain"
  # DNS check via host on the bare domain (strip any path)
  host_only="${domain%%/*}"
  if host "$host_only" >/dev/null 2>&1; then dns="ok"; else dns="fail"; fi

  if [ "$dns" = "fail" ]; then
    echo "${num}|${domain}|fail|000|DNS_FAIL" >> "$OUT"
    echo "${num} ${domain} -> DNS_FAIL"
    continue
  fi

  # curl: follow redirects, 20s max, output final code + final url
  read -r code finalurl < <(curl -sS -L --max-time 25 --retry 2 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15" \
    -o /dev/null \
    -w "%{http_code} %{url_effective}\n" \
    "$url" 2>/dev/null)
  code="${code:-000}"
  finalurl="${finalurl:-TIMEOUT}"
  echo "${num}|${domain}|${dns}|${code}|${finalurl}" >> "$OUT"
  echo "${num} ${domain} -> ${code} ${finalurl}"
done < "$INPUT"
echo "DONE"
