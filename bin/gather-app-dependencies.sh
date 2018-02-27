#!/bin/bash

usage_instructions() {
    echo -e "*** ERRO"
    echo -e "Instruções de uso:"
    echo -e "Parâmetros:"
    echo -e "\t-d APP_DIR (informa o diretório a escanear) * obrigatório"
    echo -e "\t-a APP_NAME (informa o nome da aplicação) * obrigatório"
    echo -e "\t-k (mantem arquivo temporário no disco)"
    echo -e "\t-c (exporta cypher ao invés de CSV)"
}

KEEP_GENERATED_FILE=false
CYPHER=false
CSV=true

while getopts ":d:a:kc" opt; do
  case $opt in
    d)
        APP_DIR=$OPTARG
      ;;
    a)
        APP_NAME=$OPTARG
      ;;
    k)
        KEEP_GENERATED_FILE=true
      ;;
    c)
        CYPHER=true
        CSV=false
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z ${APP_DIR} || -z ${APP_NAME} ]]; then
    usage_instructions
    exit 1    
fi

TMP_FILE=/tmp/$(basename ${0})_$RANDOM
CSV_FILE=/tmp/$(basename ${0})_$RANDOM.csv
CYPHER_FILE=/tmp/$(basename ${0})_$RANDOM.cypher

MODULES=$(find $APP_DIR -maxdepth 1 -type d -exec basename {} \; | sort | uniq | xargs)

#docker run --rm -v $APP_DIR:/opt/workdir uai.mp.rs.gov.br:8082/uai/snakefood /bin/bash -c "
sfood /opt/workdir | sfood-cluster ${MODULES} | grep ", ('/opt/workdir'," | sed "s/'\/opt\/workdir'\, //g" > ${TMP_FILE}

# Geração do CSV (cabeçalho)
echo "APP_NAME;MODULE;DEPENDENCIES" >> ${CSV_FILE}

# Geração do Cypher
echo "MERGE (app:PythonApp { name:'${APP_NAME}' })" >> ${CYPHER_FILE}

# Geração do CSV (conteúdo)
for module in $MODULES; do
    module_tmp=module_${RANDOM}_${RANDOM}
    echo "MERGE (${module_tmp}:PythonModule { name:'${module}' })" >> ${CYPHER_FILE}
    echo "MERGE (app)-[:CONTAINS]->(${module_tmp})" >> ${CYPHER_FILE}
    dependencies=`grep "(('${module}')," ${TMP_FILE} | grep -oP ", \('.*'\)\)$" | cut -d"'" -f2 | xargs | sed 's/ /,/g'`
    OLD_IFS=${IFS}
    IFS=','
    for dependency in $dependencies; do
        dependency_tmp=dependency_$RANDOM
        echo "MERGE (${dependency_tmp}:PythonModule { name:'${dependency}' })" >> ${CYPHER_FILE}
        echo "MERGE (${module_tmp})-[:DEPENDS_ON]->(${dependency_tmp})" >> ${CYPHER_FILE}
    done
    IFS=${OLD_IFS}
    echo "${APP_NAME};${module};${dependencies}" >> ${CSV_FILE}
done

echo ";" >> ${CYPHER_FILE}

if [ "${KEEP_GENERATED_FILE}" == true ]; then
    echo Mantido arquivo temporário ${TMP_FILE}
else
    rm ${TMP_FILE}
fi

if [ "${CSV}" == true ]; then
    cat ${CSV_FILE}
else
    cat ${CYPHER_FILE}
fi
#echo Gerado CSV ${CSV_FILE}
