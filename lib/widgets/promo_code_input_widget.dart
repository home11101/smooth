import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/promo_code_service.dart';
import '../utils/app_theme.dart';

class PromoCodeInputWidget extends StatefulWidget {
  final Function(PromoCodeValidation)? onCodeValidated;
  final Function(String)? onCodeApplied;
  final String? initialCode;
  final String? context;
  final bool showApplyButton;

  const PromoCodeInputWidget({
    Key? key,
    this.onCodeValidated,
    this.onCodeApplied,
    this.initialCode,
    this.context,
    this.showApplyButton = true,
  }) : super(key: key);

  @override
  State<PromoCodeInputWidget> createState() => _PromoCodeInputWidgetState();
}

class _PromoCodeInputWidgetState extends State<PromoCodeInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final PromoCodeService _promoCodeService = PromoCodeService();

  PromoCodeValidation? _validation;
  bool _isValidating = false;
  bool _isApplied = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialCode ?? '';
    
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _validateCode();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _validation = null;
        _isValidating = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validation = null;
    });

    try {
      final validation = await _promoCodeService.validatePromoCode(
        _controller.text.trim(),
        context: widget.context,
      );

      setState(() {
        _validation = validation;
        _isValidating = false;
      });

      widget.onCodeValidated?.call(validation);
    } catch (e) {
      debugPrint('Erreur lors de la validation du code promo : ${e.toString()}');
      setState(() {
        _validation = PromoCodeValidation(
          isValid: false,
          errorMessage: 'Erreur de connexion. Réessayez.',
        );
        _isValidating = false;
      });
    }
  }

  Future<void> _applyCode() async {
    if (_validation == null || !_validation!.isValid) return;

    setState(() {
      _isApplied = true;
    });

    try {
      final success = await _promoCodeService.applyPromoCode(
        _controller.text.trim(),
        _validation!.discountValue ?? 0.0,
      );

      if (success) {
        widget.onCodeApplied?.call(_controller.text.trim());
        _showSuccessSnackBar();
      } else {
        _showErrorSnackBar('Erreur lors de l\'application du code promo');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'application du code promo : ${e.toString()}');
      _showErrorSnackBar('Erreur de connexion');
    }

    setState(() {
      _isApplied = false;
    });
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Code promo appliqué avec succès !'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _validation?.isValid == true 
              ? Colors.green.shade400 
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code promo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Avez-vous un code promo ?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Entrez votre code promo',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: _isValidating
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _validation?.isValid == true
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 24,
                                )
                              : _validation?.isValid == false
                                  ? Icon(
                                      Icons.error,
                                      color: Colors.red.shade600,
                                      size: 24,
                                    )
                                  : null,
                    ),
                    onChanged: (value) {
                      _controller.value = _controller.value.copyWith(
                        text: value.toUpperCase(),
                        selection: TextSelection.collapsed(offset: value.length),
                      );
                      if (_validation != null) {
                        setState(() {
                          _validation = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _validateCode(),
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.showApplyButton)
                  ElevatedButton(
                    onPressed: _isValidating || _isApplied
                        ? null
                        : _validation?.isValid == true
                            ? _applyCode
                            : _validateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _validation?.isValid == true
                          ? Colors.green.shade600
                          : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _isApplied
                            ? const Icon(Icons.check, size: 20)
                            : Text(
                                _validation?.isValid == true ? 'Appliquer' : 'Valider',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seules les lettres (A-Z) et chiffres sont acceptés. Les minuscules sont converties automatiquement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_validation != null) ...[
              const SizedBox(height: 12),
              _buildValidationMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationMessage() {
    if (_validation!.isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code promo valide !',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (_validation!.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _validation!.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _validation!.errorMessage ?? 'Code promo invalide',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
} 