import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/offer_service.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final String currentUserId;
  final Function(OfferModel) onOfferUpdated;

  const OfferCard({
    super.key,
    required this.offer,
    required this.currentUserId,
    required this.onOfferUpdated,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  late OfferService _offerService;
  bool _isLoading = false;

  bool get _isSender => widget.offer.senderId == widget.currentUserId;
  bool get _isReceiver => widget.offer.receiverId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    try {
      _offerService = Get.find<OfferService>();
    } catch (_) {
      _offerService = Get.put(OfferService());
    }
  }

  Future<void> _acceptOffer() async {
    // Confirm before deducting money
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text('Confirm Payment',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Accepting this offer will deduct ₦${widget.offer.amount.toStringAsFixed(0)} from your Wisper wallet and pay it to the seller immediately.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1877F2)),
              child: const Text('Accept & Pay', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.acceptOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar(
        'Payment Successful',
        '₦${widget.offer.amount.toStringAsFixed(0)} paid to seller from your wallet.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception:', '').trim(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _declineOffer() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.declineOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar('Offer Declined', 'The offer has been declined.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline offer',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payOffer() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text('Confirm Payment',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Pay ₦${widget.offer.amount.toStringAsFixed(0)} for this offer?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pay', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.payOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar('Payment Successful', '₦${widget.offer.amount.toStringAsFixed(0)} paid!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Payment failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.offer.status == OfferStatus.PENDING;
    final isAccepted = widget.offer.status == OfferStatus.ACCEPTED;
    final isDeclined = widget.offer.status == OfferStatus.DECLINED;
    final isPaid = widget.offer.status == OfferStatus.PAID;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded,
                    color: Color(0xff1877F2), size: 15),
                const SizedBox(width: 6),
                const Text(
                  'Service Offer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(widget.offer.status),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  widget.offer.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Price
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('₦',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Offer price',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(
                          '₦${widget.offer.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery time
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_rounded,
                          color: Colors.white70, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery time',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(
                          widget.offer.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 10),

                // ── Action Buttons ───────────────────────────────
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())

                // Receiver sees Accept/Decline when PENDING
                else if (_isReceiver && isPending) ...[
                  _buildButton(
                    label: 'Accept & Pay ₦${widget.offer.amount.toStringAsFixed(0)}',
                    color: const Color(0xff1877F2),
                    textColor: Colors.white,
                    onTap: _acceptOffer,
                  ),
                  const SizedBox(height: 8),
                  _buildButton(
                    label: 'Decline',
                    color: Colors.transparent,
                    textColor: Colors.grey,
                    onTap: _declineOffer,
                    border: true,
                  ),
                ]

                // Sender sees Cancel when PENDING
                else if (_isSender && isPending)
                  _buildButton(
                    label: 'Cancel Offer',
                    color: Colors.transparent,
                    textColor: Colors.grey,
                    onTap: _declineOffer,
                    border: true,
                  )

                // Final states
                else if (isPaid)
                  _buildStatusRow(Icons.check_circle, 'Payment Completed', Colors.green)
                else if (isDeclined)
                  _buildStatusRow(Icons.cancel, 'Offer Declined', Colors.red)
                else if (isAccepted)
                  _buildStatusRow(Icons.check_circle, 'Offer Accepted', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OfferStatus status) {
    Color color;
    String label;
    switch (status) {
      case OfferStatus.PENDING:
        color = Colors.orange;
        label = 'Pending';
        break;
      case OfferStatus.ACCEPTED:
        color = Colors.green;
        label = 'Accepted';
        break;
      case OfferStatus.DECLINED:
        color = Colors.red;
        label = 'Declined';
        break;
      case OfferStatus.PAID:
        color = Colors.blue;
        label = 'Paid';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool border = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: border
                ? Border.all(color: Colors.grey.withOpacity(0.3))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
