import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PaymentMethod { card, bankTransfer, cash }

class CardDetails {
  final String holderName;
  final String number;
  final String expiry;
  final String cvv;

  CardDetails({
    required this.holderName,
    required this.number,
    required this.expiry,
    required this.cvv,
  });
}

class PaymentMethodSheet extends StatefulWidget {
  final double amount;
  final String currency;
  final String? title;
  final String? subtitle;
  final PaymentMethod defaultMethod;
  final List<PaymentMethod> allowedMethods;
  final bool busy;
  final VoidCallback onClose;
  final void Function({required PaymentMethod method, CardDetails? card}) onConfirm;

  const PaymentMethodSheet({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.title,
    this.subtitle,
    this.defaultMethod = PaymentMethod.card,
    this.allowedMethods = const [
      PaymentMethod.card,
      PaymentMethod.bankTransfer,
      PaymentMethod.cash
    ],
    this.busy = false,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();

  static Future<void> show({
    required BuildContext context,
    required double amount,
    String currency = 'USD',
    String? title,
    String? subtitle,
    PaymentMethod defaultMethod = PaymentMethod.card,
    List<PaymentMethod> allowedMethods = const [
      PaymentMethod.card,
      PaymentMethod.bankTransfer,
      PaymentMethod.cash
    ],
    required void Function({required PaymentMethod method, CardDetails? card})
        onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSheet(
        amount: amount,
        currency: currency,
        title: title,
        subtitle: subtitle,
        defaultMethod: defaultMethod,
        allowedMethods: allowedMethods,
        onClose: () => Navigator.pop(context),
        onConfirm: onConfirm,
      ),
    );
  }
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  late PaymentMethod _selectedMethod;
  final _holderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.defaultMethod;
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  bool get _isCardValid {
    if (_selectedMethod != PaymentMethod.card) return true;

    final trimmedNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiryMatch =
        RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').hasMatch(_expiryController.text);

    return _holderNameController.text.trim().length > 2 &&
        RegExp(r'^\d{16}$').hasMatch(trimmedNumber) &&
        expiryMatch &&
        RegExp(r'^\d{3,4}$').hasMatch(_cvvController.text.trim());
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  void _handleConfirm() {
    if (!_isCardValid || widget.busy) return;

    final card = _selectedMethod == PaymentMethod.card
        ? CardDetails(
            holderName: _holderNameController.text,
            number: _cardNumberController.text,
            expiry: _expiryController.text,
            cvv: _cvvController.text,
          )
        : null;

    widget.onConfirm(method: _selectedMethod, card: card);
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank transfer';
      case PaymentMethod.cash:
        return 'Pay on arrival';
    }
  }

  String _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Pay now with credit or debit card';
      case PaymentMethod.bankTransfer:
        return 'We will email instructions after booking';
      case PaymentMethod.cash:
        return 'Settle directly with your host at check-in';
    }
  }

  String _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.cash:
        return '💵';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'Choose payment method',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle ??
                        'Total due ${_formatCurrency(widget.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Payment methods list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ...widget.allowedMethods.map((method) {
                      final isSelected = _selectedMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedMethod = method),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0061FF)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: isSelected
                                  ? const Color(0xFF0061FF).withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _getMethodIcon(method),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getMethodLabel(method),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getMethodDescription(method),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF0061FF)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0061FF)
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Card details form
                    if (_selectedMethod == PaymentMethod.card) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Card details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _holderNameController,
                        decoration: InputDecoration(
                          hintText: 'Name on card',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cardNumberController,
                        decoration: InputDecoration(
                          hintText: 'Card number',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          _CardNumberFormatter(),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryController,
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryDateFormatter(),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _cvvController,
                              decoration: InputDecoration(
                                hintText: 'CVV',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Not now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCardValid && !widget.busy
                          ? _handleConfirm
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0061FF),
                        disabledBackgroundColor: const Color(0xFF0061FF)
                            .withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: widget.busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
