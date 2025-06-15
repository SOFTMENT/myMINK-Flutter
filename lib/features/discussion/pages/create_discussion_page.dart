import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class CreateDiscussionPage extends StatefulWidget {
  const CreateDiscussionPage({Key? key}) : super(key: key);

  @override
  State<CreateDiscussionPage> createState() => _CreateDiscussionPageState();
}

class _CreateDiscussionPageState extends State<CreateDiscussionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final user = UserModel.instance;
    final doc = FirebaseFirestore.instance.collection('Discussions').doc();

    await doc.set({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'replyCount': 0,
    });

    if (mounted) {
      Navigator.of(context).pop(); // back to list
      // optionally show a toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic created')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomAppBar(
                title: 'New Discussion Topic',
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        textAlignVertical: TextAlignVertical.top,
                        controller: _titleCtrl,
                        decoration: buildInputDecoration(
                          labelText: 'Enter a short, descriptive title',
                          prefixIcon: null,
                          fillColor: AppColors.white,
                        ),
                        maxLength: 80,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: buildInputDecoration(
                          alignLabelWithHint: true,
                          labelText: 'What do you want to discuss?',
                          prefixIcon: null,
                          fillColor: AppColors.white,
                        ),
                        maxLines: 6,
                        minLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: _isSubmitting ? 'Posting…' : 'Post Topic',
                        backgroundColor: AppColors.textBlack,
                        onPressed: () {
                          _isSubmitting ? null : _submit();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
