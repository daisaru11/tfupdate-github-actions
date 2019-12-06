FROM minamijoyo/tfupdate

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]