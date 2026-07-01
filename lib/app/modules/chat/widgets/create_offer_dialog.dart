import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/offer_service.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';

class CreateOfferDialog extends StatefulWidget {
  final String receiverId;
  final String chatId;
  final Function(OfferModel) onOfferCreated;

  const CreateOfferDialog({
    super.key,
    required this.receiverId,
    required this.chatId,
    required this.onOfferCreated,
  });

  @override
  State<CreateOfferDialog> createState() => _CreateOfferDialogState();
}

class _CreateOfferDialogState extends State<CreateOfferDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _durationUnit = 'Days'; // 'Hours' or 'Days'
  late final OfferService _offerService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _offerService = Get.find<OfferService>();
    } catch (e) {
      _offerService = Get.put(OfferService());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    if (_amountController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _durationController.text.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount greater than 0',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final offer = await _offerService.createOffer(
        receiverId: widget.receiverId,
        chatId: widget.chatId,
        amount: amount,
        description: _descriptionController.text.trim(),
        duration: '${_durationController.text.trim()} $_durationUnit',
      );

      if (mounted) {
        widget.onOfferCreated(offer);
        Navigator.pop(context);
        Get.snackbar(
          'Offer Sent',
          'Your offer has been sent successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send offer';
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection') ||
            e.toString().contains('Failed host lookup')) {
          errorMessage = 'Cannot connect to server. Please try again later.';
        } else if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Feature not available yet. Please contact support.';
        } else {
          errorMessage = e.toString().replaceAll('Exception:', '').trim();
        }
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ──────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel
                  GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _isLoading ? Colors.grey : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Create Offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Send button
                  GestureDetector(
                    onTap: _isLoading ? null : _sendOffer,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xff1877F2)),
                            ),
                          )
                        : const Text(
                            'Send',
                            style: TextStyle(
                              color: Color(0xff1877F2),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xff2C2C2E), thickness: 1, height: 1),

            // ── Form Body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── PRICE ────────────────────────────────────────
                    const Text(
                      'PRICE',
                      style: TextStyle(
                        color: Color(0xff8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Text(
                              '₦',
                              style: TextStyle(
                                color: Color(0xff8E8E93),
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 17),
                              decoration: const InputDecoration(
                                hintText: 'Enter amount',
                                hintStyle: TextStyle(
                                  color: Color(0xff48484A),
                                  fontSize: 17,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── DELIVERY TIME ────────────────────────────────
                    const Text(
                      'DELIVERY TIME',
                      style: TextStyle(
                        color: Color(0xff8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Number input
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 17),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 3',
                                hintStyle: TextStyle(
                                  color: Color(0xff48484A),
                                  fontSize: 17,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 14),
                              ),
                            ),
                          ),

                          // Divider
                          Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xff3C3C3E),
                          ),

                          // Hours / Days toggle
                          StatefulBuilder(
                            builder: (context, setInnerState) {
                              return Row(
                                children: ['Hours', 'Days'].map((unit) {
                                  final selected = _durationUnit == unit;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _durationUnit = unit);
                                      setInnerState(() {});
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xff1877F2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        unit,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xff8E8E93),
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── DESCRIPTION ──────────────────────────────────
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        color: Color(0xff8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17),
                        decoration: const InputDecoration(
                          hintText: 'Describe the service you are offering...',
                          hintStyle: TextStyle(
                            color: Color(0xff48484A),
                            fontSize: 17,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
