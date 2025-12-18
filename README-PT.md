# Deskbox - Ambiente de Desktop Remoto

Container Docker com Debian 12 (Bookworm) + Xfce4 + XRDP para acesso remoto via Remote Desktop Protocol.

## Recursos

- **Base**: Debian 12 (Bookworm) - Release estáveling
- **Ambiente Desktop**: Xfce4 (com auto-configuração no primeiro login)
- **Acesso Remoto**:
  - XRDP (porta 3389) - Remote Desktop Protocol
  - SSH (porta 2222) - Acesso via terminal seguro
- **Backend**: xorgxrdp (Xorg nativo)
- **Múltiplos Usuários**: Suporte completo (sessões simultâneas)
- **Usuário Padrão**: deskbox (UID 1000)
- **Hostname**: deskbox
- **Timezone**: America/Cuiaba
- **Persistência**: Todos os diretórios home em `/mnt/deskbox/home`
- **Healthcheck**: Monitoramento automático do serviço XRDP
- **Logging**: Logs estruturados para startup e eventos XRDP
- **Ferramentas Pré-instaladas**: git, vim, htop, tmux, tree, e mais
- **Profile Customizado**: Aliases úteis e prompt colorido

## Início Rápido

### 1. Configurar Ambiente (Obrigatório)

Copie o arquivo de exemplo e personalize:

```bash
cp .env.example .env
```

Depois edite o `.env` para definir seus valores:

```bash
# Configuração Docker Hub
DOCKER_USER=carlosrabelo
IMAGE_NAME=deskbox
VERSION=0.0.1

# Configuração do Usuário
USER_PASSWORD=sua_senha_segura_aqui

# Configuração do Sistema
TZ=America/Cuiaba
```

**IMPORTANTE**: Nunca faça commit do arquivo `.env` no Git!

### Opções de Segurança

#### Configuração Padrão
```bash
# Usa variáveis de ambiente do .env
make start CTX=hostname
```

#### Configuração de Produção (Recomendado)
```bash
# Define senha segura no arquivo .env
echo "USER_PASSWORD=sua_senha_segura" >> .env
make start CTX=hostname
```

### Notas Importantes de Segurança

1. **Gerenciamento de Senhas**
   - **Desenvolvimento**: Variáveis de ambiente (arquivo `.env`)
   - **Nunca commite senhas no Git**

2. **Acesso de Rede**
   - **Padrão**: RDP exposto em `0.0.0.0:3389`
   - **Seguro**: Você pode restringir para localhost definindo `RDP_BIND_ADDRESS=127.0.0.1` no `.env`
   - **Túnel SSH**: Opção mais segura para acesso remoto

### 2. Inicializar Diretórios (Primeira vez)

```bash
make init CTX=hostname
```

### 3. Construir Imagem

```bash
make build CTX=hostname
```

### 4. Iniciar Container

```bash
make start CTX=hostname
```

### 5. Conectar ao Debian-RDP

**Opção 1: RDP (Desktop Gráfico)**

Use um cliente RDP (como Remmina, Microsoft Remote Desktop, ou rdesktop):

```bash
# Linux
rdesktop -u debian-rdp -p sua_senha hostname:3389

# Ou com Remmina
# Host: hostname:3389
# Usuário: debian-rdp
# Senha: a que você definiu no .env
```

**Opção 2: SSH (Acesso via Terminal)**

Conecte via SSH para acesso por linha de comando:

```bash
# Acesso SSH
ssh -p 2222 debian-rdp@hostname

# Ou com SCP para transferir arquivos
scp -P 2222 arquivo.txt debian-rdp@hostname:/home/debian-rdp/
```

## Comandos Make Disponíveis

| Comando | Descrição |
|---------|-----------|
| `make init` | Inicializa estrutura de diretórios no host remoto |
| `make build` | Constrói a imagem Docker (cria tags VERSION e latest) |
| `make push` | Envia imagens para Docker Hub (VERSION e latest) |
| `make start` | Inicia o container |
| `make stop` | Para o container |
| `make restart` | Reinicia o container |
| `make ps` | Lista containers em execução |
| `make logs` | Exibe logs do Docker Compose em tempo real |
| `make view-logs` | Visualiza logs de startup e XRDP do Debian-RDP |
| `make sessions` | Mostra sessões de usuários ativos |
| `make backup` | Cria backup de /mnt/debian-rdp/home |
| `make exec SVC=debian-rdp` | Abre shell no container |
| `make config` | Exibe configuração do Docker Compose |
| `make clean` | Remove imagens Docker locais (versão atual) |
| `make clean-all` | Para containers e remove todas as imagens do projeto |

Todos os comandos aceitam `CTX=<context>` para especificar o host Docker remoto e podem sobrescrever variáveis do `.env`.

## Múltiplos Usuários

O container funciona como um sistema Debian normal - você pode adicionar quantos usuários precisar!

### Usuário Padrão

- **Usuário**: debian-rdp
- **UID**: 1000
- **Senha**: Definida via `.env` (variável `USER_PASSWORD`)

### Adicionando Novos Usuários

Como um sistema Debian normal, use comandos nativos:

**Método 1: Usando `adduser` (Recomendado - Interativo)**

```bash
# Entrar no container
make exec SVC=debian-rdp CTX=hostname

# Adicionar o usuário (comando interativo do Debian)
adduser john

# Isso vai:
# 1. Criar o usuário
# 2. Solicitar senha
# 3. Criar diretório home
# 4. Solicitar informações opcionais (nome completo, etc)

# Adicionar ao grupo sudo (opcional)
usermod -aG sudo john

# Configurar sessão Xfce4
echo "startxfce4" > /home/john/.xsession
```

**Método 2: Usando `useradd` (Não-interativo)**

```bash
# Entrar no container
make exec SVC=debian-rdp CTX=hostname

# Criar o usuário
useradd -m -s /bin/bash mary

# Definir a senha
passwd mary

# Adicionar ao grupo sudo (opcional)
usermod -aG sudo mary

# Configurar sessão Xfce4
echo "startxfce4" > /home/mary/.xsession
```

### Conectando com Diferentes Usuários

Cada usuário pode conectar simultaneamente via RDP:

```bash
# Usuário 1: debian-rdp
rdesktop -u debian-rdp -p senha_debian-rdp hostname:3389

# Usuário 2: john (em outra sessão)
rdesktop -u john -p senha_john hostname:3389

# Usuário 3: mary (em outra sessão)
rdesktop -u mary -p senha_mary hostname:3389
```

### Recursos de Múltiplos Usuários

**Cada usuário tem:**
- Diretório home separado e persistente
- Sessão Xfce4 independente
- Configurações próprias
- Permissões sudo (por padrão)

**Suporte para:**
- Múltiplas sessões simultâneas
- Dados persistidos no volume `/mnt/debian-rdp/home`
- Estrutura padrão (Desktop, Documents, etc)

### Gerenciando Usuários

Entre no container e use comandos Debian padrão:

```bash
make exec SVC=debian-rdp CTX=hostname
```

**Listar usuários:**
```bash
cat /etc/passwd | grep /home
# ou
cut -d: -f1 /etc/passwd
```

**Remover usuário:**
```bash
deluser --remove-home john  # Comando Debian
# ou
userdel -r john             # Comando Linux tradicional
```

**Alterar senha:**
```bash
passwd john
```

**Ver informações do usuário:**
```bash
id john
groups john
```

## Considerações de Segurança

### Avisos Importantes

1. **NOPASSWD sudo**: O usuário `debian-rdp` pode executar comandos sudo SEM senha
   - **Risco**: Se alguém ganhar acesso ao usuário, terá controle total do container
   - **Recomendação**: Use apenas em ambientes controlados/desenvolvimento
   - **Produção**: Remova `NOPASSWD` da linha 181 no Dockerfile

2. **Senha via Variável de Ambiente**
   - Senhas são definidas em runtime via `USER_PASSWORD`
   - **Melhor prática**: Use Docker secrets em produção
   - Nunca exponha `USER_PASSWORD` em logs ou repositórios

3. **Porta 3389 Exposta**
   - RDP não é criptografado por padrão
   - **Recomendação**: Use VPN ou túnel SSH em redes não confiáveis
   - Considere usar `ports: - "127.0.0.1:3389:3389"` e túnel SSH

4. **Sandbox do Chromium**
   - Chromium roda com flag `--no-sandbox` (necessário para containers)
   - **Seguro**: Docker provê isolamento no nível do container (namespaces, cgroups, seccomp)
   - O navegador ainda está isolado do sistema host
   - Esta é a abordagem padrão para executar navegadores em containers

### Melhorias de Segurança Recomendadas

Para ambientes de produção:

1. **Remover NOPASSWD**:
   ```dockerfile
   # Linha 181 no Dockerfile
   echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
   ```

2. **Usar Docker Secrets**:
   ```yaml
   secrets:
     - user_password
   ```

3. **Túnel SSH para RDP**:
   ```bash
   ssh -L 3389:localhost:3389 user@hostname
   # Então conecte RDP para localhost:3389
   ```

4. **Firewall/Políticas de Rede**:
   - Restrinja acesso à porta 3389 apenas de IPs confiáveis

## Estrutura de Volumes

```
/mnt/debian-rdp/
    ├── home/                    → /home (no container)
    │   ├── debian-rdp/              # Usuário padrão (UID 1000)
    │   │   ├── Desktop/
    │   │   ├── Documents/
    │   │   ├── Downloads/
    │   │   ├── Pictures/
    │   │   └── Videos/
    │   ├── john/                # Usuários adicionais
    │   ├── mary/
    │   └── ...
    │
    └── logs/                    → /var/log/debian-rdp (no container)
        ├── startup.log          # Logs de inicialização do Debian-RDP
        └── xrdp.log             # Logs do servidor XRDP
```

**Dados persistidos no host:**
- **Diretórios home**: `/mnt/debian-rdp/home/*` - Todos os dados, configurações e arquivos dos usuários
- **Logs**: `/mnt/debian-rdp/logs/*` - Logs de startup e XRDP para troubleshooting

## Ferramentas Pré-instaladas

Debian-RDP vem com ferramentas essenciais de desenvolvimento e sistema pré-instaladas:

**Ferramentas de Desenvolvimento:**
- git - Controle de versão
- vim - Editor de texto
- tmux - Multiplexador de terminal
- tree - Visualização de diretórios

**Monitoramento do Sistema:**
- htop - Visualizador interativo de processos
- net-tools - Utilitários de rede
- iputils-ping - Diagnóstico de rede

**Aplicações Desktop:**
- Chromium - Navegador web (otimizado para containers)
- Thunar - Gerenciador de arquivos
- Mousepad - Editor de texto
- Xfce4 Terminal - Emulador de terminal
- Task Manager - Monitor do sistema
- Screenshot Tool - Ferramenta de captura de tela

**Aliases Customizados (disponíveis no terminal):**
```bash
ll          # Listagem detalhada de arquivos (ls -lah)
gs          # Git status
gp          # Git pull
gc          # Git commit
gd          # Git diff
update      # Atualização do sistema (apt update && upgrade)
ports       # Mostrar portas de rede (netstat)
```

## Logging e Monitoramento

Debian-RDP implementa logging estruturado para melhor troubleshooting:

**Visualizar logs de startup:**
```bash
make view-logs CTX=hostname
```

**Monitorar sessões ativas:**
```bash
make sessions CTX=hostname
```

**Visualizar logs do Docker em tempo real:**
```bash
make logs CTX=hostname
```

**Arquivos de log (persistidos no host em `/mnt/debian-rdp/logs/`):**
- `startup.log` - Logs do processo de startup
- `xrdp.log` - Logs do servidor XRDP

**Nota**: Os logs são persistidos no host, portanto sobrevivem a reinicializações e rebuilds do container.

## Backup e Restore

**Criar backup:**
```bash
make backup CTX=hostname
```

Isso cria um arquivo de backup com timestamp em `/tmp/debian-rdp-backup-YYYYMMDD-HHMMSS.tar.gz` no host remoto.

O backup inclui:
- Todos os diretórios home dos usuários (`/mnt/debian-rdp/home/*`)
- Todos os logs (`/mnt/debian-rdp/logs/*`)

**Restaurar a partir do backup:**
```bash
# No host remoto
ssh root@hostname
cd /tmp
tar -xzf debian-rdp-backup-20250113-120000.tar.gz -C /
```

**Backup manual de diretórios específicos:**
```bash
# Backup apenas dos diretórios home
ssh root@hostname "tar -czf /tmp/debian-rdp-home-backup.tar.gz /mnt/debian-rdp/home"

# Backup apenas dos logs
ssh root@hostname "tar -czf /tmp/debian-rdp-logs-backup.tar.gz /mnt/debian-rdp/logs"
```

## Solução de Problemas

### Não consigo conectar via RDP

1. Verifique se o container está rodando:
   ```bash
   make ps CTX=hostname
   ```

2. Verifique o status de saúde do container:
   ```bash
   docker ps  # Procure pelo status "healthy"
   ```

3. Verifique os logs:
   ```bash
   make logs CTX=hostname
   # Ou visualize os logs específicos do Debian-RDP
   make view-logs CTX=hostname
   ```

4. Teste conectividade:
   ```bash
   telnet hostname 3389
   ```

### Não consigo conectar via SSH

1. Verifique se a porta SSH está exposta:
   ```bash
   docker ps | grep debian-rdp
   # Deve mostrar 0.0.0.0:2222->22/tcp
   ```

2. Teste conectividade SSH:
   ```bash
   telnet hostname 2222
   ```

3. Tente conectar com modo verbose:
   ```bash
   ssh -v -p 2222 debian-rdp@hostname
   ```

### Tela preta após login

1. Verifique os logs do Debian-RDP para erros:
   ```bash
   make view-logs CTX=hostname
   ```

2. Verifique permissões do diretório home:
   ```bash
   make exec SVC=debian-rdp CTX=hostname
   ls -la /home/debian-rdp
   ```

3. Verifique a configuração do XFCE4:
   ```bash
   make exec SVC=debian-rdp CTX=hostname
   cat /home/debian-rdp/.xsession
   # Deve conter: startxfce4
   ```

4. Reinicie o container:
   ```bash
   make restart CTX=hostname
   ```

### "USER_PASSWORD não definido"

Verifique se o arquivo `.env` existe e contém:
```bash
USER_PASSWORD=sua_senha
```

## Variáveis de Ambiente

Todas as variáveis de ambiente devem ser configuradas no arquivo `.env` (copie de `.env.example`):

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `DOCKER_USER` | carlosrabelo | Nome de usuário do Docker Hub |
| `IMAGE_NAME` | debian-rdp | Nome da imagem Docker |
| `USER_NAME` | debian-rdp | Nome do usuário padrão |
| `USER_PASSWORD` | debian-rdp | Senha RDP (altere isso!) |

## Arquitetura

```
┌─────────────────────────────────────┐
│  Cliente RDP (Remmina/mstsc)        │
│  Cliente SSH (Terminal)             │
└──────────┬──────────────┬───────────┘
           │ Porta 3389   │ Porta 2222
           │ (RDP)        │ (SSH)
┌──────────▼──────────────▼───────────┐
│         Container Docker            │
│  ┌───────────────────────────────┐  │
│  │       Servidor XRDP           │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │  Gerenciador de Sessão XRDP   │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │     Xorg (xorgxrdp)           │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │    Desktop Xfce4              │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │      Servidor SSH             │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Licença

Licença MIT - Use por sua própria conta e risco.

## Contribuindo

PRs são bem-vindos! Para mudanças maiores, por favor abra uma issue primeiro.

## Suporte

Para problemas ou perguntas, por favor abra uma issue no repositório.
