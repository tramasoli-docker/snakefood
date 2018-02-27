# SNAKEFOOD Docker Image

## Objetivo

Geração de lista de dependências em APPs Django. Para mais informações visite 

## Prossupostos

### Estrutura do repositório git

- /files/snakefood
  
### Conteúdo dos arquivos

- /files/snakefood
 - fontes da aplicação


## Configuração

### S.O.

Imagem herda de python:2.7-jessie (portanto é Debian 8).

### Volumes

- /opt/workdir (opcional)
  - propósito: monte aqui repositório git que deseja inspecionar

## Uso

### Gerando relatórios

#### Dependências internas da APP

```shell
APP_DIR=/home/tramasoli/git/mprs/sites/intra/django17/
docker run --rm -v $APP_DIR:/opt/workdir uai.mp.rs.gov.br:8082/uai/snakefood /bin/bash -c "sfood /opt/workdir | sfood-cluster $(find $APP_DIR -maxdepth 1 -type d -exec basename {} \; | xargs) | grep \", ('/opt/workdir',\" | sed \"s/'\/opt\/workdir'\, //g\""
```
