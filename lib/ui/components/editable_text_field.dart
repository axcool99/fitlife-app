import 'package:flutter/material.dart';
import 'components.dart';

/// EditableTextField - An inline editable text field with save/cancel actions
class EditableTextField extends StatefulWidget {
  final String initialValue;
  final TextInputType keyboardType;
  final bool readOnly;
  final Future<void> Function(String)? onSave;
  final void Function(String)? onChanged;

  const EditableTextField({
    super.key,
    required this.initialValue,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onSave,
    this.onChanged,
  });

  @override
  _EditableTextFieldState createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;
  String _originalValue = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _originalValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
      _originalValue = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.readOnly) return;
    setState(() {
      _isEditing = true;
      _originalValue = _controller.text;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = _originalValue;
    });
  }

  Future<void> _save() async {
    if (widget.onSave == null) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave!(_controller.text);
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _originalValue = _controller.text;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FitLifeTheme.highlightPink,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              style: TextStyle(
                color: FitLifeTheme.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: FitLifeTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: FitLifeTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: FitLifeTheme.accentGreen,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: FitLifeTheme.surfaceColor,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => _save(),
              autofocus: true,
            ),
          ),
          const SizedBox(width: 8),
          if (_isSaving)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(FitLifeTheme.accentGreen),
              ),
            )
          else
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: FitLifeTheme.accentGreen,
                    size: 20,
                  ),
                  onPressed: _save,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: FitLifeTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: _cancelEditing,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                _controller.text.isEmpty ? 'Not set' : _controller.text,
                type: AppTextType.body,
                color: _controller.text.isEmpty ? FitLifeTheme.textSecondary : FitLifeTheme.textPrimary,
              ),
            ),
            if (!widget.readOnly)
              Icon(
                Icons.edit,
                size: 16,
                color: FitLifeTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}