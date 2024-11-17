#!/bin/bash
docker container stop misp_db misp_web
docker container rm misp_db misp_web
rm -rf /srv/MISP/*
