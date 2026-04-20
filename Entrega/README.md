# algorithm_control

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


 📱O FeedControl é um aplicativo móvel desenvolvido em Flutter que utiliza um algoritmo de recomendação personalizado para organizar o consumo de informação. O objetivo do projeto é combater a sobrecarga de informações, permitindo que o usuário defina seus interesses e o app "aprenda" com seu comportamento em tempo real.

🚀 Funcionalidades PrincipaisCuradoria de Interesses (Cold Start): Ao iniciar o app, o usuário seleciona temas de interesse que recebem pesos iniciais para calibrar o feed.Algoritmo de Ranking Dinâmico: Os posts são ordenados por uma fórmula matemática que considera o peso da categoria, curtidas e comentários.Aprendizado Contínuo: O app utiliza feedback implícito (curtidas/comentários) para ajustar os pesos das categorias no banco de dados via Firebase.Controle de Bloqueio: Permite ocultar categorias ou posts indesejados, garantindo a segurança e o bem-estar digital do usuário.Persistência em Tempo Real: Integração total com Cloud Firestore para sincronização imediata de dados.🛠️ Arquitetura e TecnologiasUI Framework: Flutter (Dart)Backend: FirebaseCloud Firestore: Banco de dados NoSQL para posts e perfis de usuário.Firebase Auth: Autenticação segura de usuários.Gerenciamento de Estado: StatefulWidget e StreamBuilder para atualizações reativas.

🧠 O Algoritmo de RecomendaçãoO diferencial técnico do projeto é o motor de ranking. Cada post recebe um Score calculado pela seguinte lógica:$$Score = (PesoCategoria \times 1000) + (Engajamento \times 5) + (Curtidas \times 0.1). Como o app aprende?Explícito: O usuário escolhe "Política" -> Peso base = 100.0.Implícito: O usuário curte um post -> O código executa FieldValue.increment(0.05).Filtragem: Posts de categorias bloqueadas são removidos da lista antes do cálculo de ranking.

📂 Estrutura do Projeto (Principais Arquivos)lib/pages/interesses_page.dart: Interface de seleção inicial e definição de pesos no Firestore.lib/services/post_service.dart: O "coração" do app, onde reside o cálculo do algoritmo e a busca de dados.lib/pages/feed_page.dart: Exibição reativa dos posts ordenados pelo Score.⚙️ Como rodar o projetoCertifique-se de ter o Flutter instalado (flutter doctor).Clone o repositório:Bashgit clone https://github.com/secclew/feedcontrol.git
Instale as dependências:Bashflutter pub get
Configure seu projeto no Firebase e baixe o arquivo google-services.json para a pasta android/app/.Execute o app:Bashflutter run

👨‍💻 DesenvolvedorEduardo - Desenvolvimento Full Stack e Engenharia de Dados


link para o video: https://drive.google.com/file/d/1afAO2a1FUSzANTDDhe06XEo1tham_zu5/view?usp=drive_link
