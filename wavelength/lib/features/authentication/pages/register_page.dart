import 'package:flutter/material.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form key til validering af input
  final _formKey = GlobalKey<FormState>();
  // Kontrollerer om kodeord skal være skjult eller synligt
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers til at gemme kodeord værdier
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // SingleChildScrollView gør siden scrollbar hvis der ikke er plads
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Opret bruger',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                // Form container med fast bredde på 300
                SizedBox(
                  width: 300,
                  child: Form(
                    key: _formKey, // Brugt til validering af alle felter
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Fornavn',
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Udfyld feltet' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Efternavn',
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Udfyld feltet' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Email',
                          ),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Udfyld feltet';
                            if (!v!.contains('@')) return 'Ugyldig email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Fødselsdag feltet med datepicker
                        TextFormField(
                          controller: _birthdayController,
                          readOnly: true, // Kan ikke skrive direkte i feltet
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Fødselsdag',
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            // Åbner datepicker kalender
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            // Gemmer datoen hvis brugeren valgte en
                            if (pickedDate != null) {
                              _birthdayController.text = 
                                '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                            }
                          },
                          validator: (v) => v?.isEmpty ?? true ? 'Udfyld feltet' : null,
                        ),
                        const SizedBox(height: 12),
                        // Kodeord felt med vis/skjul knap
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword, // Hvis true: stjerner, hvis false: viser tekst
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Kodeord',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                // Skifter mellem at vise og skjule kodeord
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            // Tjekker at feltet ikke er tomt og mindst 6 tegn
                            if (v?.isEmpty ?? true) return 'Udfyld feltet';
                            if (v!.length < 6) return 'Mindst 6 tegn';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Bekræftelse af kodeord felt
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Bekræft kodeord',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                // Skifter mellem at vise og skjule bekræftelse kodeord
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            // Tjekker at bekræftelse matcher det oprindelige kodeord
                            if (v?.isEmpty ?? true) return 'Udfyld feltet';
                            if (v != _passwordController.text) return 'Kodeordene stemmer ikke';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Knap der validerer alle felter før registrering
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              // Validerer alle felter i formularen
                              if (_formKey.currentState!.validate()) {
                                // TODO: Implementer registrering logik
                              }
                            },
                            child: const Text(
                              'Opret bruger',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Link tilbage til login siden
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Har du allerede en konto? '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder:(context) => const LoginPage(),
                        )
                      ),
                      child: const Text(
                        'Log ind',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
