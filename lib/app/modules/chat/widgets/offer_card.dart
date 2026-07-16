import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/currency_helper.dart';
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
  String get _sym => CurrencyHelper.deviceSymbol;

  @override
  void initState() {
    super.initState();
    try {
      _offerService = Get.find<OfferService>();
    } catch (_) {
      _offerService = Get.put(OfferService());
    }
  }

  // ── Accept offer — buyer pays into escrow ──────────────────
  Future<void> _acceptOffer() async {
    final buyerFee = widget.offer.amount * 0.05;
    final total = widget.offer.amount + buyerFee;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text('Confirm Payment to Escrow',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offer amount:  $_sym${widget.offer.amount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Platform fee (5%):  $_sym${buyerFee.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white24, height: 16),
            Text(
              'Total deducted:  $_sym${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Funds are held in escrow and released to the seller only when you confirm job completion.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1877F2),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  )),
              child: const Text('Accept & Pay to Escrow',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.acceptOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar(
        'Payment in Escrow ✅',
        '$_sym${widget.offer.amount.toStringAsFixed(0)} is held safely in escrow.',
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

  // ── Release payment — buyer confirms job done ──────────────
  Future<void> _releasePayment() async {
    final sellerFee = widget.offer.amount * 0.05;
    final sellerGets = widget.offer.amount - sellerFee;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text('Release Payment to Seller?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escrow amount:  $_sym${widget.offer.amount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Platform fee (5%):  -$_sym${sellerFee.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white24, height: 16),
            Text(
              'Seller receives:  $_sym${sellerGets.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.greenAccent, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action is irreversible. Only release if you are satisfied with the work delivered.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  )),
              child: const Text('Release Payment',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.releaseOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar(
        'Payment Released 💰',
        'Seller has been paid $_sym${sellerGets.toStringAsFixed(2)}.',
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

  // ── Open dispute ───────────────────────────────────────────
  Future<void> _openDispute() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text('Open Dispute?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Our team will review this case and resolve the dispute. Funds remain in escrow until resolved.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  )),
              child: const Text('Open Dispute',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _offerService.disputeOffer(widget.offer.id);
      widget.onOfferUpdated(updated);
      Get.snackbar(
        'Dispute Opened ⚠️',
        'Our team will review and resolve this shortly.',
        backgroundColor: Colors.orange,
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

  // ── Decline / Cancel ───────────────────────────────────────
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

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPending = widget.offer.status == OfferStatus.PENDING;
    final isAccepted = widget.offer.status == OfferStatus.ACCEPTED;
    final isDeclined = widget.offer.status == OfferStatus.DECLINED;
    final isPaid = widget.offer.status == OfferStatus.PAID;
    final isReleased = widget.offer.status == OfferStatus.RELEASED;
    final isDisputed = widget.offer.status == OfferStatus.DISPUTED;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Color(0xff1877F2), size: 15),
                const SizedBox(width: 6),
                const Text('Send Offer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const Spacer(),
                _buildStatusBadge(widget.offer.status),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(widget.offer.description,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
                const SizedBox(height: 10),

                // Price
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(_sym,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Offer price',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        Text(
                          '$_sym${widget.offer.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
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
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.access_time_rounded,
                          color: Colors.white70, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery time',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        Text(widget.offer.duration,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),

                // Escrow info banner when ACCEPTED
                if (isAccepted) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_sym${widget.offer.amount.toStringAsFixed(0)} is held in escrow. Release when job is done.',
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Divider(
                    color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 10),

                // ── Action Buttons ─────────────────────────────
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())

                // Receiver: Accept/Decline when PENDING
                else if (_isReceiver && isPending) ...[
                  _buildButton(
                    label: 'Accept & Pay to Escrow',
                    color: const Color(0xff1877F2),
                    textColor: Colors.white,
                    onTap: _acceptOffer,
                  ),
                  const SizedBox(height: 8),
                  _buildButton(
                    label: 'Decline',
                    color: Colors.transparent,
                    textColor: Colors.white,
                    onTap: _declineOffer,
                    border: true,
                  ),
                ]

                // Sender: Cancel when PENDING
                else if (_isSender && isPending)
                  _buildButton(
                    label: 'Cancel Offer',
                    color: Colors.transparent,
                    textColor: Colors.white,
                    onTap: _declineOffer,
                    border: true,
                  )

                // Buyer: Release Payment + Open Dispute when ACCEPTED (in escrow)
                else if (_isReceiver && isAccepted) ...[
                  _buildButton(
                    label: 'Release Payment',
                    color: Colors.green,
                    textColor: Colors.white,
                    onTap: _releasePayment,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 8),
                  _buildButton(
                    label: 'Open Dispute',
                    color: Colors.transparent,
                    textColor: Colors.orange,
                    onTap: _openDispute,
                    border: true,
                    borderColor: Colors.orange.withOpacity(0.5),
                  ),
                ]

                // Seller: waiting for release when ACCEPTED
                else if (_isSender && isAccepted)
                  _buildStatusRow(
                      Icons.hourglass_top_rounded,
                      'Offer Accepted — awaiting payment release',
                      Colors.blueAccent)

                // Final states
                else if (isReleased)
                  _buildStatusRow(
                      Icons.check_circle, 'Payment Released', Colors.green)
                else if (isPaid)
                  _buildStatusRow(
                      Icons.check_circle, 'Payment Completed', Colors.green)
                else if (isDeclined)
                  _buildStatusRow(
                      Icons.cancel, 'Offer Declined', Colors.red)
                else if (isDisputed)
                  _buildStatusRow(
                      Icons.warning_amber_rounded,
                      'Dispute Under Review',
                      Colors.orange),
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
        color = Colors.blue;
        label = 'In Escrow';
        break;
      case OfferStatus.DECLINED:
        color = Colors.red;
        label = 'Declined';
        break;
      case OfferStatus.PAID:
        color = Colors.green;
        label = 'Paid';
        break;
      case OfferStatus.RELEASED:
        color = Colors.green;
        label = 'Released';
        break;
      case OfferStatus.DISPUTED:
        color = Colors.orange;
        label = 'Disputed';
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
    Color? borderColor,
    IconData? icon,
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
                ? Border.all(
                    color: borderColor ?? Colors.white.withOpacity(0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
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
        Flexible(
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
