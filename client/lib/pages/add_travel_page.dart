import 'package:flutter/material.dart';
import '../services/travel_service.dart';

class AddTravelPage extends StatefulWidget {
  const AddTravelPage({super.key});

  @override
  State<AddTravelPage> createState() => _AddTravelPageState();
}

class _AddTravelPageState extends State<AddTravelPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final descriptionController = TextEditingController();

  // Dropdown seçimleri
  String? selectedPurpose;
  String? selectedCategory;

  // Tarihler
  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;

  // Seçenek listeleri
  final List<String> purposes = ["Turistik", "Eğitim", "Aile ziyareti", "İş"];
  final List<String> categories = [
    "Kültürel",
    "Business",
    "Gastronomi",
    "Doğa",
    "Tarihi",
  ];

  @override
  void dispose() {
    countryController.dispose();
    cityController.dispose();
    districtController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Tarih seçici — locale KALDIRILDI (flutter_localizations gerekmez)
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? now) : (endDate ?? startDate ?? now),
      firstDate: DateTime(2000),
      lastDate: now,
      // locale satırı kaldırıldı → MaterialLocalizations hatası çözüldü
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(picked)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Seçilmedi";
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen başlangıç ve bitiş tarihlerini seçin."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen gezi amacını seçin."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen gezi kategorisini seçin."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await TravelService().createTravel(
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        district: districtController.text.trim(),
        startDate: startDate!.toIso8601String(),
        endDate: endDate!.toIso8601String(),
        purpose: selectedPurpose!,
        category: selectedCategory!,
        description: descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seyahat başarıyla eklendi! ✈️"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seyahat Ekle"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── KONUM BİLGİLERİ ──────────────────────────────────
              _sectionTitle("📍 Konum Bilgileri"),
              const SizedBox(height: 8),
              TextFormField(
                controller: countryController,
                decoration: _inputDecoration("Ülke *"),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Ülke zorunludur" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cityController,
                decoration: _inputDecoration("Şehir *"),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Şehir zorunludur" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: districtController,
                decoration: _inputDecoration("İlçe / Bölge (opsiyonel)"),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 24),

              // ── TARİH BİLGİLERİ ──────────────────────────────────
              _sectionTitle("📅 Seyahat Tarihleri"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _datePickerButton(
                      label: "Gidiş Tarihi *",
                      value: _formatDate(startDate),
                      onTap: () => _pickDate(isStart: true),
                      hasValue: startDate != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePickerButton(
                      label: "Dönüş Tarihi *",
                      value: _formatDate(endDate),
                      onTap: () => _pickDate(isStart: false),
                      hasValue: endDate != null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── GEZİ AMACI VE KATEGORİ ───────────────────────────
              _sectionTitle("🎯 Gezi Türü"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPurpose,
                decoration: _inputDecoration("Gezi Amacı *"),
                items: purposes
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedPurpose = val),
                validator: (v) => v == null ? "Lütfen amaç seçin" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: _inputDecoration("Gezi Kategorisi *"),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                validator: (v) => v == null ? "Lütfen kategori seçin" : null,
              ),

              const SizedBox(height: 24),

              // ── AÇIKLAMA ─────────────────────────────────────────
              _sectionTitle("✍️ Gezi Deneyiminiz"),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                decoration:
                    _inputDecoration(
                      "Gezinizi anlatın... (maks. 1500 karakter)",
                    ).copyWith(
                      alignLabelWithHint: true,
                      hintText:
                          "Gittiğiniz yerler, yaptığınız aktiviteler, tavsiyeler...",
                    ),
                maxLines: 7,
                maxLength: 1500,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Açıklama zorunludur";
                  }
                  if (v.trim().length < 20) return "En az 20 karakter giriniz";
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── GÖRSELLER (İleride) ───────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Görseller yakında eklenecek",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      "Bilet fotoğrafı ve gezi fotoğrafları",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── KAYDET BUTONU ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Seyahati Kaydet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _datePickerButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasValue ? Colors.deepPurple : Colors.grey.shade400,
            width: hasValue ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: hasValue ? Colors.deepPurple : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
