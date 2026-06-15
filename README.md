# 💧 HidroBalance

> Aplicativo multiplataforma para avaliação padronizada da taxa de sudorese e suporte à tomada de decisão em hidratação de atletas.

Projeto acadêmico semestral desenvolvido no **Instituto Mauá de Tecnologia (IMT)**, em parceria com o **Centro Universitário São Camilo**.

---

## 📋 Sobre o Projeto

O HidroBalance permite coletar, calcular e monitorar o **balanço hídrico** em sessões de treino e competição, gerando recomendações individualizadas de ingestão de fluidos e eletrólitos com base nos dados do atleta e do contexto ambiental.

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia |
|--------|-----------|
| Mobile & Web | Flutter (Dart) |
| Banco de dados | Firebase Firestore (NoSQL, offline nativo) |
| Autenticação | Firebase Auth |
| Armazenamento | Firebase Storage |
| Backend | Firebase (BaaS — sem backend próprio) |

---

## 📁 Estrutura do Projeto

```
lib/
├── models/
│   ├── sessao.dart
│   ├── usuario.dart
│   └── vinculo.dart
├── screens/
│   ├── auth/
│   │   ├── tela_cadastro.dart
│   │   ├── tela_esqueci_senha.dart
│   │   └── tela_login.dart
│   ├── home/
│   │   └── widgets/
│   │       ├── home_atleta.dart
│   │       ├── home_profissional.dart
│   │       ├── tela_historico_atleta.dart
│   │       └── tela_home.dart
│   └── sessao/
│       ├── tela_durante_sessao.dart
│       ├── tela_pos_sessao.dart
│       ├── tela_pre_sessao.dart
│       ├── tela_recomendacoes.dart
│       └── tela_resultado_sessao.dart
├── services/
│   ├── autenticacao.dart
│   ├── calculo_sudorese.dart
│   ├── relatorio_service.dart
│   ├── sessao_service.dart
│   ├── usuario_service.dart
│   └── vinculo_service.dart
├── theme/
│   └── tema_app.dart
├── firebase_options.dart
└── main.dart
```

---

## 👥 Perfis de Usuário

O app possui perfis para atletas e profissionais (nutricionistas, treinadores e médicos), gerenciados via **Firebase Auth**:

- 🏃 **Atleta** — registra sessões e acompanha seu histórico individual
- 🩺 **Profissional** — monitora atletas vinculados, visualiza dados das sessões e acessa relatórios

Todos os dados são identificados por **código do atleta** (sem nome exposto), com criptografia local e em trânsito.

---

## ⚙️ Fluxo de Sessão

### 1. Pré-Sessão
- Massa corporal (após esvaziamento vesical, vestimenta padronizada)
- Condições ambientais (temperatura, umidade, vento, exposição solar)
- Modalidade, duração prevista, intensidade e tipo de vestimenta
- Estado basal do atleta (cor da urina, sede, sintomas, histórico de hidratação)

### 2. Durante a Sessão
- Registro de ingestão de fluidos por atalhos de volume (squeeze, copo, garrafa)
- Volume urinário quando aplicável

### 3. Pós-Sessão
- Massa corporal pós-exercício nas mesmas condições
- Registro de roupas encharcadas ou troca de vestimenta (com alerta de impacto no erro da medida)
- Sintomas gastrointestinais, fadiga e tolerância ao plano hídrico

---

## 🧮 Motor de Cálculo

O app calcula automaticamente:

- **Perda de massa corporal ajustada** — diferença pré/pós corrigida pela ingestão e urina eliminada
- **Taxa de sudorese estimada** — perda ajustada ÷ duração (L/h)
- **% de variação de massa corporal** — indicador de desidratação aguda
- **Balanço hídrico da sessão** — perda estimada vs ingestão realizada

Com base nesses dados, gera recomendações individualizadas:

- Faixa alvo de ingestão em mL/h
- Sugestão de fracionamento por intervalos (ex: a cada 10–20 minutos)
- Alertas de risco de perda excessiva ou superingestão

---

## 🗺️ Arquitetura de Telas — 11 telas em 3 fases

### Fase 1 — Fundação
- Login e Cadastro
- Esqueci Senha
- Tela Inicial (Home)

### Fase 2 — Fluxo de Sessão
- Pré-Sessão
- Durante a Sessão
- Pós-Sessão
- Resultado da Sessão
- Recomendações

### Fase 3 — Histórico e Painel
- Histórico de Sessões
- Perfil do Atleta
- Painel do Profissional (atletas vinculados e alertas)
- Exportação de Relatório

---

## ✨ Funcionalidades Adicionais

- 📄 **Exportação de relatórios** em PDF e planilha (por atleta, por sessão e por período)
- ✅ **Checklists de padronização** obrigatórios com detecção de inconsistências e alertas para valores implausíveis

---

## 🚀 Como Executar

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado e configurado
- Xcode (para iOS/macOS) e CocoaPods
- Conta no Firebase com projeto configurado
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) instalado

### Configuração

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/hidrobalance.git
cd hidrobalance

# Instale as dependências
flutter pub get

# Configure o Firebase (já inclui firebase_options.dart gerado pelo FlutterFire CLI)
flutterfire configure

# Execute o app
flutter run
```

### Plataformas suportadas

```bash
flutter run -d chrome      # Web
flutter run -d ios         # iOS
flutter run -d android     # Android
flutter run -d macos       # macOS
```

---

## 🔒 Segurança e Privacidade

- Dados identificados por **código do atleta**, sem nome exposto
- Criptografia local e em trânsito
- Regras de segurança configuradas no Firestore (`firestore.rules`)

---

## 🎨 Identidade Visual

A identidade segue o padrão do **Centro Universitário São Camilo**:

- Cor primária: `#C41230` — aplicado na AppBar, botões de ação principal e valores de destaque
- Design system: **Material Design** com componentes nativos do Flutter (sem biblioteca de UI externa)

---

## 🏫 Contexto Acadêmico

Projeto desenvolvido como entregável semestral do curso de Ciência da Computação no **Instituto Mauá de Tecnologia (IMT)**, em parceiria com o **Centro Universitário São Camilo**

---

## 📄 Licença

Este projeto é de uso acadêmico. Todos os direitos reservados aos autores, ao Instituto Mauá de Tecnologia e ao Centro Universitário São Camilo
