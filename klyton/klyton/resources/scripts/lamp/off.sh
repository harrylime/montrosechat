#!/bin/bash
source ../resources/scripts/lamp/common.sh
ssh -i ../resources/keys/id_rsa_klyton klyton@$ssh "curl http://127.0.0.1:8550/off" &
