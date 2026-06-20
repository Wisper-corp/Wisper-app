import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/offer_service.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';
import 'package:intl/intl.dart';

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
  final OfferService _offerService = Get.find<OfferService>();
  bool _isLoading = false;

  bool get _isSender => widget.offer.senderId == widget.currentUserId;
  bool get _isReceiver => widget.offer.receiverId == widget.currentUserId;

  Future<void> _acceptOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOffer = await _offerService.acceptOffer(widget.offer.id);
      widget.onOfferUpdated(updatedOffer);
      Get.snackbar(
        'Success',
        'Offer accepted. You can now proceed to payment.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _declineOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOffer = await _offerService.declineOffer(widget.offer.id);
      widget.onOfferUpdated(updatedOffer);
      Get.snackbar(
        'Success',
        'Offer declined',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _payOffer() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xff1C1C1E),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to pay ₦${NumberFormat('#,##0.00').format(widget.offer.amount)} for this offer?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFFD700),
            ),
            child: const Text(
              'Pay',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOffer = await _offerService.payOffer(widget.offer.id);
      widget.onOfferUpdated(updatedOffer);
      Get.snackbar(
        'Success',
        'Payment successful!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (widget.offer.status) {
      case OfferStatus.PENDING:
        return const Color(0xffFFD700);
      case OfferStatus.ACCEPTED:
        return Colors.green;
      case OfferStatus.DECLINED:
        return Colors.red;
      case OfferStatus.PAID:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (widget.offer.status) {
      case OfferStatus.PENDING:
        return 'Pending';
      case OfferStatus.ACCEPTED:
        return 'Accepted';
      case OfferStatus.DECLINED:
        return 'Declined';
      case OfferStatus.PAID:
        return 'Paid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: _getStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Offer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Amount
          Row(
            children: [
              const Text(
                'Amount:',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '₦${NumberFormat('#,##0.00').format(widget.offer.amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            widget.offer.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          // Duration
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Delivery Time: ${widget.offer.duration}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Sender/Receiver info
          Text(
            _isSender
                ? 'To: ${widget.offer.receiverName}'
                : 'From: ${widget.offer.senderName}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          // Action buttons
          if (_isReceiver && widget.offer.status == OfferStatus.PENDING)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _declineOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          
          // Pay button
          if (_isReceiver && widget.offer.status == OfferStatus.ACCEPTED)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _payOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFD700),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          
          // Time
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy - HH:mm').format(widget.offer.createdAt),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
