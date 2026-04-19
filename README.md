# FeedControl 📱

O **FeedControl** é um aplicativo móvel desenvolvido em Flutter que utiliza um algoritmo de recomendação personalizado para organizar o consumo de informação. O objetivo do projeto é combater a sobrecarga de informações, permitindo que o usuário defina seus interesses e o app "aprenda" com seu comportamento em tempo real.

## 📺 Demonstração em Vídeo
Confira o funcionamento do aplicativo e a explicação técnica do algoritmo no link abaixo:
👉 [Assista ao vídeo do FeedControl](https://drive.google.com/file/d/1afAO2a1FUSzANTDDhe06XEo1tham_zu5/view?usp=drive_link)

---

## 🚀 Funcionalidades Principais

* **Curadoria de Interesses (Cold Start):** Ao iniciar o app, o usuário seleciona temas de interesse que recebem pesos iniciais para calibrar o feed.
* **Algoritmo de Ranking Dinâmico:** Os posts são ordenados por uma fórmula que considera o peso da categoria e o engajamento.
* **Aprendizado Contínuo:** O app utiliza feedback implícito (curtidas/interações) para ajustar os pesos das categorias no banco de dados via Firebase.
* **Controle de Bloqueio:** Permite ocultar categorias indesejadas, garantindo o bem-estar digital do usuário.
* **Persistência em Tempo Real:** Integração total com Cloud Firestore para sincronização imediata.

## 🛠️ Arquitetura e Tecnologias

* **UI Framework:** Flutter (Dart)
* **Backend:** Firebase
* **Cloud Firestore:** Banco de dados NoSQL para posts e perfis de usuário.
* **Firebase Auth:** Autenticação segura de usuários.
* **Gerenciamento de Estado:** StatefulWidget e StreamBuilder para atualizações reativas.

## 🧠 O Algoritmo de Recomendação

O diferencial técnico do projeto é o motor de ranking. Cada post recebe um **Score** calculado pela seguinte lógica:

$$Score = (PesoCategoria \times 1000) + (Engajamento \times 5) + (Curtidas \times 0.1)$$

### Como o app aprende?
1.  **Explícito:** O usuário escolhe uma categoria (ex: "Tecnologia") -> Peso base definido.
2.  **Implícito:** O usuário interage com um post -> O código executa `FieldValue.increment(0.05)` no perfil do usuário, aumentando a relevância daquele tema para o futuro.
3.  **Filtragem:** Posts de categorias bloqueadas são removidos da lista antes do cálculo de ranking.

## 📂 Estrutura do Projeto (Principais Arquivos)

* `lib/pages/interesses_page.dart`: Interface de seleção inicial e definição de pesos no Firestore.
* `lib/services/post_service.dart`: O "coração" do app, onde reside o cálculo do algoritmo e a busca de dados.
* `lib/pages/feed_page.dart`: Exibição reativa dos posts ordenados pelo Score.

## ⚙️ Como rodar o projeto localmente

> **Nota:** Por questões de segurança, as chaves de API do Firebase foram removidas deste repositório.

1.  Certifique-se de ter o Flutter instalado (`flutter doctor`).
2.  Clone o repositório:
    ```bash
    git clone [https://github.com/secclew/feedcontrol.git](https://github.com/secclew/feedcontrol.git)
    ```
3.  Instale as dependências:
    ```bash
    flutter pub get
    ```
4.  **Configuração Firebase:**
    * Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
    * Baixe seu arquivo `google-services.json` exclusivo.
    * Cole o arquivo em: `algorithm_control/android/app/`.
5.  Execute o app:
    ```bash
    flutter run
    ```

---
**👨‍💻 Desenvolvedor**
Eduardo - Desenvolvimento Full Stack e Engenharia de Dados.