import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool isLoading = true;
  bool isSaving = false;
  String profileImage = "";

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = await UserService.getUserProfile();

    if (!mounted) return;

    if (user != null) {
      fullNameController.text = user["fullName"] ?? "";
      usernameController.text = user["username"] ?? "";
      emailController.text = user["email"] ?? "";
      phoneController.text = user["phone"] ?? "";
      cityController.text = user["city"] ?? "";
      profileImage = user["profileImage"] ?? "";
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 45,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    setState(() {
      profileImage = "data:image/png;base64,$base64Image";
    });
  }

  Future<void> saveProfile() async {
    setState(() {
      isSaving = true;
    });

    final result = await UserService.updateUserProfile(
      fullName: fullNameController.text.trim(),
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      city: cityController.text.trim(),
      profileImage: profileImage,
    );

    setState(() {
      isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "İşlem tamamlandı."),
        backgroundColor: result["success"] == true ? Colors.green : Colors.red,
      ),
    );

    if (result["success"] == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yeni şifreler eşleşmiyor."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await UserService.changePassword(
      oldPassword: oldPasswordController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "İşlem tamamlandı."),
        backgroundColor: result["success"] == true ? Colors.green : Colors.red,
      ),
    );

    if (result["success"] == true) {
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: const Icon(Icons.edit, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Ayarları")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: profileImage.isNotEmpty
                        ? MemoryImage(
                            base64Decode(profileImage.split(",").last),
                          )
                        : null,
                    child: profileImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: pickProfileImage,
                    // onPressed: () {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text(
                    //         "Profil resmi yükleme kısmını sonraki adımda bağlayacağız.",
                    //       ),
                    //     ),
                    //   );
                    // },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Profil Resmini Değiştir"),
                  ),

                  const SizedBox(height: 20),

                  buildEditableField(
                    label: "Ad Soyad",
                    icon: Icons.person,
                    controller: fullNameController,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "Kullanıcı Adı",
                    icon: Icons.alternate_email,
                    controller: usernameController,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "E-posta",
                    icon: Icons.email,
                    controller: emailController,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "Telefon",
                    icon: Icons.phone,
                    controller: phoneController,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "Şehir",
                    icon: Icons.location_city,
                    controller: cityController,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveProfile,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isSaving ? "Kaydediliyor..." : "Bilgileri Kaydet",
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Şifre Değiştir",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  buildEditableField(
                    label: "Eski Şifre",
                    icon: Icons.lock,
                    controller: oldPasswordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "Yeni Şifre",
                    icon: Icons.lock_outline,
                    controller: newPasswordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),

                  buildEditableField(
                    label: "Yeni Şifre Tekrar",
                    icon: Icons.lock_reset,
                    controller: confirmPasswordController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: changePassword,
                      icon: const Icon(Icons.password),
                      label: const Text("Şifreyi Değiştir"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
