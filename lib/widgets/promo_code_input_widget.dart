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
    // N'affiche la snackbar que si aucun feedback instantané n'est visible
    if (!mounted) return;
    final isValid = _validation?.isValid == true;
    final hasFeedback = isValid || (_validation != null && _validation!.isValid == false);
    if (!hasFeedback) {
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
    final isValid = _validation?.isValid == true;
    final isInvalid = _validation != null && _validation!.isValid == false;
    final hasError = _validation?.errorMessage != null && _validation!.errorMessage!.isNotEmpty;
    final discountMsg = isValid && _validation?.discountValue != null
        ? (_validation!.discountType == 'percentage'
            ? '-${_validation!.discountValue!.toInt()}% sur votre abonnement'
            : 'Réduction : ${_validation!.discountValue}')
        : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isValid
              ? Colors.green.shade400
              : isInvalid
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppTheme.primaryBlue, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Code promo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Avez-vous un code promo ? Utilisez-le pour obtenir une réduction.',
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
                            color: Colors.grey.shade400,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    // La validation ne se fait plus à chaque frappe
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Feedback instantané uniquement après validation
            if (_isValidating)
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Vérification du code...', style: TextStyle(color: Colors.blueGrey)),
                ],
              )
            else if (isValid)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('Code valide', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  if (discountMsg != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(discountMsg, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              )
            else if (isInvalid)
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Code invalide', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  if (hasError) ...[
                    const SizedBox(width: 8),
                    Flexible(child: Text(_validation!.errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ],
              ),
            // Exemple de code
            const SizedBox(height: 4),
            Text('Exemple : SMOOTH10', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            if (widget.showApplyButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isValidating || _isApplied
                      ? null
                      : _validateCode,
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text('Valider le code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isValid && widget.showApplyButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !_isApplied ? _applyCode : null,
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text('Appliquer le code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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