#!/bin/bash

# Este script pode ser usado para:
# Fazer backup, compactar e enviar para o S3(AWS)
# Ex.: ./script.sh backup <nome_do_banco_dados>
# Listar os arquivos no S3(AWS)
# Ex.: ./script.sh list
# Fazer download do arquivo do S3, descomactar e fazer o restore no banco de dados.
# Ex.: ./script.sh restore <nome_do_arquivo>

export PATH=/bin:/usr/bin:/usr/local/bin
#nome do bakcup
NAME_BACKUP=$(date '+%Y%m%d_%H%M%S')
NAME_ARQ=kitnet-$(date '+%Y%m%d_%H%M%S')
NAME_REST="$2"
NAME_DIR=cut -s -d"." -f1  ${NAME_REST} 
MONGO_HOST='localhost'
MONGO_PORT='27017'
DATABASE_NAMES="$2"

backup() {
    echo "Executando backup para bancos de dados selecionado ${DATABASE_NAMES}"
    mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} --db ${DATABASE_NAMES} --out dumps/kitnet-${NAME_BACKUP}/
    mv dumps/kitnet-${NAME_BACKUP}/kitnet/* dumps/kitnet-${NAME_BACKUP}
    rmdir dumps/kitnet-${NAME_BACKUP}/kitnet
}

compress(){
    tar -cvzf database.tar.gz  dumps/kitnet-${NAME_BACKUP}* 
    cp -r database.tar.gz ${NAME_ARQ}.tar.gz
    rm -r database.tar.gz dumps
    
}

unzip(){
    tar -xvf ${NAME_REST}
    mongorestore --host ${MONGO_HOST} --port ${MONGO_PORT} dumps/${NAME_DIR}
    rm -r dumps
}

upload_s3(){
    # envia backup para o S3 AWS - Não esquecer de: export AWS_PROFILE=UserProfile(AWS)
    aws s3 cp ${NAME_ARQ}.tar.gz s3://bcpmongoragazzi/database/ --include ${NAME_ARQ}.tar.gz 
}


download_s3(){
    # recebe backup do S3 AWS - Não esqucer de: export AWS_PROFILE=UserProfile(AWS)
    aws s3 cp s3://bcpmongoragazzi/database/${NAME_REST} ./  
}

list_s3(){
    # Lista arquivos do S3 (AWS)0
    aws s3 ls s3://bcpmongoragazzi/database/ > info.txt
    cut -d' ' -f9 info.txt
    rm -r info.txt
    
}

case $1 in
  backup)
    backup "$2"
    compress
    # upload_s3
    ;;

  list)
    list_s3
    ;;

  restore)
    # download_s3
    # sleep 5
    unzip "$2"
    ;;

  *)
    echo "Erro, opcao inválida"
    ;;
esac



