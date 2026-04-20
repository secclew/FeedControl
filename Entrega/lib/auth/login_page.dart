import 'package:algorithm_control/pages/interesses_page.dart';
import 'package:flutter/material.dart';
import '../pages/feed_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool _mostrarSenha = false;
  bool _ehLogin = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// FUNÇÃO LOGIN
  Future<void> login() async {

    if (emailController.text.isEmpty || senhaController.text.isEmpty) {
      _mostrarErro("Preencha todos os campos");
      return;
    }

    try {

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InteressesPage()),
      );

    } on FirebaseAuthException catch (e) {

      String erro = "Erro ao entrar";

      if (e.code == 'user-not-found') {
        erro = "Usuário não encontrado";
      }

      if (e.code == 'wrong-password') {
        erro = "Senha incorreta";
      }

      _mostrarErro(e.message ?? erro);

    }

  }

  /// FUNÇÃO CRIAR CONTA
  Future<void> criarConta() async {

    if (emailController.text.isEmpty || senhaController.text.isEmpty) {
      _mostrarErro("Preencha todos os campos para cadastrar");
      return;
    }

    if (senhaController.text != confirmarSenhaController.text) {
      _mostrarErro("As senhas não coincidem");
      return;
    }

    try {

      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      await _firestore.collection("users").doc(uid).set({
        "email": emailController.text.trim(),
        "criadoEm": FieldValue.serverTimestamp(),
        "tipoConta": "usuario",
        "seguindo": [],
        "interesses":[],
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conta criada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedPage()),
      );

    } on FirebaseAuthException catch (e) {

      _mostrarErro(e.message ?? "Erro ao criar conta");

    }

  }

  /// MOSTRAR ERRO
  void _mostrarErro(String mensagem) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Login FeedControl"),
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Center(

          child: Container(

            constraints: const BoxConstraints(maxWidth: 400),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Text(
                  _ehLogin
                      ? "Bem-vindo de volta!"
                      : "Crie sua conta",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                /// EMAIL
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "exemplo@email.com",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 20),

                /// SENHA
                TextField(
                  controller: senhaController,
                  obscureText: !_mostrarSenha,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarSenha
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarSenha = !_mostrarSenha;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// CONFIRMAR SENHA (SÓ NO CADASTRO)
                if (!_ehLogin) ...[
                  TextField(
                    controller: confirmarSenhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirmar senha",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                /// BOTÃO ENTRAR / CRIAR CONTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {

                      if (_ehLogin) {
                        login();
                      } else {
                        criarConta();
                      }

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _ehLogin ? "Entrar" : "Criar Conta",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// ALTERNAR LOGIN / CADASTRO
                TextButton(
                  onPressed: () {

                    setState(() {
                      _ehLogin = !_ehLogin;
                    });

                  },
                  child: Text(
                    _ehLogin
                        ? "Não tem uma conta? Cadastre-se"
                        : "Já tem uma conta? Faça login",
                  ),
                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}
          
        
      
    

            