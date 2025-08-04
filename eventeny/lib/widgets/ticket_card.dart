import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onPurchase;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = ticket.isSoldOut;
    final hasLimitedAvailability = ticket.hasLimitedAvailability;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 6,
      ),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(
          color: hasLimitedAvailability 
              ? Colors.orange.withValues(alpha: 0.3) 
              : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          gradient: hasLimitedAvailability
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.05),
                    Colors.orange.withValues(alpha: 0.02),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Type Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.type,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Price
              Text(
                '\$${ticket.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Description
              if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ticket.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Availability Row
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${ticket.availableQuantity} available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (hasLimitedAvailability) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limited',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (isSoldOut) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sold Out',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSoldOut ? null : onPurchase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isSoldOut 
                        ? Colors.grey[300] 
                        : hasLimitedAvailability 
                            ? Colors.orange[600] 
                            : Theme.of(context).primaryColor,
                    foregroundColor: isSoldOut ? Colors.grey[600] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                    ),
                    elevation: isSoldOut ? 0 : 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSoldOut ? Icons.block : Icons.shopping_cart_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSoldOut ? 'Sold Out' : 'Purchase Ticket',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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