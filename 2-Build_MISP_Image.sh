#p template_build.env .env
cp web/files/template_build.env .env
docker-compose -f docker-compose.yml build --progress=plain 2>&1 | tee build.log
