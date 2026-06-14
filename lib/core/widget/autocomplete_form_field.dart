import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/text_field.dart';

class AutocompleteFormField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> options;
  final String? Function(String?)? validator;
  final bool isMultiValue;

  const AutocompleteFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.options = const [],
    this.validator,
    this.isMultiValue = false,
  });

  @override
  State<AutocompleteFormField> createState() => _AutocompleteFormFieldState();
}

class _AutocompleteFormFieldState extends State<AutocompleteFormField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  double _fieldWidth = 0;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _onTextChanged();
    } else {
      _hideOverlay();
    }
  }

  String _getQuery() {
    if (widget.isMultiValue) {
      return widget.controller.text.split(',').last.trim().toLowerCase();
    }
    return widget.controller.text.trim().toLowerCase();
  }

  void _onTextChanged() {
    if (_isSelecting || !mounted || !_focusNode.hasFocus) return;
    final q = _getQuery();
    if (q.isEmpty) {
      _hideOverlay();
      return;
    }
    _suggestions = widget.options
        .where((o) => o.toLowerCase().contains(q))
        .take(6)
        .toList();
    if (_suggestions.isEmpty) {
      _hideOverlay();
    } else if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _fieldWidth, maxHeight: 280),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final option = _suggestions[i];
                  return InkWell(
                    onTap: () => _selectOption(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(option, style: AppTextStyles.body.copyWith(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _suggestions = [];
  }

  void _selectOption(String option) {
    _isSelecting = true;
    if (widget.isMultiValue) {
      final parts = widget.controller.text.split(',');
      final existing = parts
          .sublist(0, parts.length - 1)
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      widget.controller.text = [...existing, option].join(', ');
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
      _hideOverlay();
    } else {
      widget.controller.text = option;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: option.length),
      );
      _hideOverlay();
      _focusNode.unfocus();
    }
    _isSelecting = false;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth;
        return CompositedTransformTarget(
          link: _layerLink,
          child: AppTextField(
            label: widget.label,
            hint: widget.hint,
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
          ),
        );
      },
    );
  }
}
