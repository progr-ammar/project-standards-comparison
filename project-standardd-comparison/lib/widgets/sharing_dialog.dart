import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/deep_link_service.dart';

class SharingDialog extends StatefulWidget {
  final String deepLink;
  final String content;
  final String? title;
  final String? citation;
  final VoidCallback? onQRCodeTap;

  const SharingDialog({
    super.key,
    required this.deepLink,
    required this.content,
    this.title,
    this.citation,
    this.onQRCodeTap,
  });

  @override
  State<SharingDialog> createState() => _SharingDialogState();
}

class _SharingDialogState extends State<SharingDialog> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share),
          const SizedBox(width: 8),
          Text(widget.title ?? 'Share Content'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.citation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.citation!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sharing options
            Text(
              'Choose sharing method:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            // Share buttons grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShareButton(
                  icon: Icons.content_copy,
                  label: 'Copy Link',
                  onPressed: () => _shareContent(ShareFormat.clipboard),
                ),
                _ShareButton(
                  icon: Icons.email,
                  label: 'Email',
                  onPressed: () => _shareContent(ShareFormat.email),
                ),
                _ShareButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () => _shareContent(ShareFormat.text),
                ),
                _ShareButton(
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  onPressed: _showQRCode,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Social media options
            Text(
              'Social media:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SocialButton(
                  platform: 'twitter',
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  onPressed: () => _shareToSocial('twitter'),
                ),
                _SocialButton(
                  platform: 'linkedin',
                  icon: Icons.business,
                  label: 'LinkedIn',
                  onPressed: () => _shareToSocial('linkedin'),
                ),
                _SocialButton(
                  platform: 'facebook',
                  icon: Icons.facebook,
                  label: 'Facebook',
                  onPressed: () => _shareToSocial('facebook'),
                ),
              ],
            ),

            if (_isSharing) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _shareContent(ShareFormat format) async {
    setState(() => _isSharing = true);

    try {
      String shareText = widget.content;
      if (widget.citation != null) {
        shareText += '\n\n${widget.citation}';
      }
      shareText += '\n\nView in PM Standards App: ${widget.deepLink}';

      await _deepLinkService.shareDeepLink(
        widget.deepLink,
        text: shareText,
        format: format,
      );

      if (format == ShareFormat.clipboard && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _shareToSocial(String platform) async {
    setState(() => _isSharing = true);

    try {
      String shareText = widget.content;
      if (widget.citation != null) {
        shareText += ' - ${widget.citation}';
      }

      await _deepLinkService.shareToSocialMedia(
        widget.deepLink,
        platform: platform,
        text: shareText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to $platform: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder:
          (context) =>
              QRCodeDialog(deepLink: widget.deepLink, title: widget.title),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(onPressed: onPressed, icon: Icon(icon)),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String platform;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.platform,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(onPressed: onPressed, icon: Icon(icon)),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class QRCodeDialog extends StatelessWidget {
  final String deepLink;
  final String? title;

  const QRCodeDialog({super.key, required this.deepLink, this.title});

  @override
  Widget build(BuildContext context) {
    final deepLinkService = DeepLinkService();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code),
          const SizedBox(width: 8),
          Text(title ?? 'QR Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: deepLinkService.generateQRWidget(
              deepLink,
              size: 200,
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan this QR code to open the content in PM Standards App',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _shareQRCode(context, deepLinkService),
          child: const Text('Share QR Code'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _shareQRCode(
    BuildContext context,
    DeepLinkService service,
  ) async {
    try {
      await service.shareQRCode(deepLink);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// Utility function to show sharing dialog
Future<void> showSharingDialog(
  BuildContext context, {
  required String deepLink,
  required String content,
  String? title,
  String? citation,
}) async {
  await showDialog(
    context: context,
    builder:
        (context) => SharingDialog(
          deepLink: deepLink,
          content: content,
          title: title,
          citation: citation,
        ),
  );
}
