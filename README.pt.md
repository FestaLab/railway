# Railway
Railway é um projeto para pessoas que tem apps rodando em um PaaS como Heroku e querem mudar para AWS. Com um único comando ele é capaz de:

1. Criar uma versão customizado de um AMI com tudo o que um app Rails precisa;
2. Criar um ambiente de desenvolviment/staging com servidores web e worker, instancias redis para job e cache, banco de dados postgres e suporte para até 9 branches do seu app ao mesmo tempo;
3. Criar um ambiente de produção com load balancer, servidores web e worker, instancias redis para job e cache, banco de dados postgres com cópia de leitura, e rolling restart;
4. Fazer deploy do seu código para o ambiente de desenvolviment/staging;
5. Fazer deploy do seu código para rpodução usando rolling restarts;
6. Atualizar os servidores de produção para obter as atualizações de segurnaça mais recentes;
7. Atualizar os servidores de produção para uma nova cópia da sua AMI sem tirar seu app do ar;

Para que tudo isso funcione, o Railway faz algumas suposições sobre o tipo app que ele vai fazer deploy:

1. Puma como o servidor web;
2. Sidekiq para jobs;
3. Redis para armazenar cache e jobs;
4. Postgres como banco de dados;
5. Node/Yarn para javascript;
6. Aplicação monolito ao invés de micro serviços;
7. Ubuntu 20.04 como sistema operacional;
8. App rodando direto no OS, sem nenhum tipo de container;

Ele faz uso dos seguintes serviços do AWS:
1. EC2 para os servidores web e job;
2. Elasticache para Redis;
3. RDS para Postgres;
4. Cloudwatch para armazenar logs e olhar métricas dos servidores;
5. ELB para Load Balancer.;

Railway não é um projeto que tenta ser "web scale". Ele foi feito para pequenos times de desenvolvimento (ou programadores trabalhando sozinhos) que tem um único desenvolvedor cuidando de devops ao mesmo tempo que programa. Ele nasceu e foi para as trincheiras na [FestaLab](https://festalab.com.br/), onde nós usamos ele diariamente.  

## Instalação

Instalar esse projeto não é simples. De uma olhada no [guia de instalação](https://github.com/FestaLab/railway/blob/main/docs/INSTALL.MD), por enquanto apenas em ingles.

## Forma de Uso

Depois de instalar, a primeira coisa que você deve fazer é olhar o guia de introdução(https://github.com/FestaLab/railway/blob/main/docs/USAGE.MD), por enquanto apenas em inglês, para entender como usar o Railway no seu dia a dia.

### TODO

- Terminar de escrever os guias em portugues

## Contribuindo

Bugs e pull requests são bem vindos no Github em https://github.com/FestaLab/railway. Esse projeto tem com oobjetivo ser um espaço seguro e acolhedor para colaboração e contribuidores tem que respeitar ou [código de conduta](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md).

## License

Este projeto está disponível como open source nos termos da [licença MIT](https://opensource.org/licenses/MIT).

## Code of Conduct

Todos indivíduos interagindo com o projeto Railway tem que respeitar o [código de conduta](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md)

